module selenium.driver;

import selenium.element : Element;
import selenium.errors : WebDriverConnectionError;
import selenium.locator : ElementLocator;
import selenium.protocol.client : Client;
import selenium.types;

import conductor.http : Response, send;

import std.algorithm.searching : canFind;
import std.conv : to;
import std.json : JSONValue, parseJSON;
import std.net.curl : HTTP;
import std.process : execute, kill, Pid, spawnProcess, wait;
import std.socket;
import std.string : strip;
import core.thread : Thread;
import core.time : MonoTime, msecs;

enum DriverType
{
    Chrome,
    Firefox,
    Edge,
    Safari
}

class Driver
{
private:
    DriverType type;
    string executablePath;
    Pid pid;
    string _serverUrl;
    ushort port;
    bool _running;
    Client _client;

    this(DriverType driverType, string executablePath)
    {
        type = driverType;
        this.executablePath = executablePath;
    }

public:
    bool running() const
        => _running;

    string serverUrl() const
        => _serverUrl;

    // --- Factory methods ---

    static Driver start()
    {
        string executablePath = tryAutoDetect();
        if (executablePath is null)
        {
            throw new WebDriverConnectionError(
                "No driver configuration was set, and the default configuration failed to match on the system."
            );
        }

        DriverType type = inferTypeFromExecutable(executablePath);
        return start(type, executablePath, Capabilities.init);
    }

    static Driver start(Capabilities desiredCapabilities)
    {
        string executablePath = tryAutoDetect();
        if (executablePath is null)
        {
            throw new WebDriverConnectionError(
                "No driver configuration was set, and the default configuration failed to match on the system."
            );
        }

        DriverType type = inferTypeFromExecutable(executablePath);
        return start(type, executablePath, desiredCapabilities);
    }

    static Driver start(DriverType type)
    {
        string executablePath = autoDetectExecutable(type);
        return start(type, executablePath, Capabilities.init);
    }

    static Driver start(DriverType type, string executablePath)
    {
        return start(type, executablePath, Capabilities.init);
    }

    static Driver start(
        DriverType type,
        string executablePath,
        Capabilities desiredCapabilities,
    )
    {
        Driver ret = new Driver(type, executablePath);
        ret.launch();
        ret.createSession(desiredCapabilities);
        return ret;
    }

    // --- Process management ---

    void stop()
    {
        if (!_running || pid is Pid.init)
            return;

        tryKill(pid);
        _running = false;
        pid = Pid.init;
    }

    // --- Session lifecycle ---

    void quit()
    {
        if (_client !is null)
            _client.disconnect();

        stop();
    }

    // --- Navigation ---

    string url()
        => _client.get!string("/url");

    void url(string value)
    {
        _client.post("/url", ["url": value]);
    }

    void back()
    {
        _client.post("/back");
    }

    void forward()
    {
        _client.post("/forward");
    }

    void refresh()
    {
        _client.post("/refresh");
    }

    string title()
        => _client.get!string("/title");

    string source()
        => _client.get!string("/source");

    // --- Window / Frame ---

    string windowHandle()
        => _client.get!string("/window");

    void window(string handle)
    {
        _client.post("/window", ["handle": handle]);
    }

    string[] windowHandles()
        => _client.get!(string[])("/window/handles");

    void closeWindow()
    {
        _client.delete_("/window");
    }

    void maximize()
    {
        _client.post("/window/maximize");
    }

    Size windowSize()
        => _client.get!Size("/window/rect");

    void windowSize(Size value)
    {
        _client.post("/window/rect", value);
    }

    void frame(string id)
    {
        _client.post("/frame", ["id": id]);
    }

    void frame(long id)
    {
        _client.post("/frame", ["id": id]);
    }

    // --- Search context (Driver-level) ---

    Element findOne(string strategy)(string value)
        if (__traits(compiles, LocatorOf!strategy))
    {
        return queryElement(LocatorOf!strategy, value);
    }

    Element findOne(ElementLocator locator)
    {
        return queryElement(locator.strategy, locator.value);
    }

    Element[] findMany(string strategy)(string value)
        if (__traits(compiles, LocatorOf!strategy))
    {
        return queryElements(LocatorOf!strategy, value);
    }

    Element[] findMany(ElementLocator locator)
    {
        return queryElements(locator.strategy, locator.value);
    }

    Element activeElement()
    {
        return new Element(
            this,
            _client.post!(WebElement)("/element/active")
        );
    }

    // --- JavaScript / Screenshot ---

    T executeScript(T = string)(string script, JSONValue args = JSONValue.emptyArray)
    {
        return _client.post!T("/execute", [
            "script": JSONValue(script),
            "args": args,
        ]);
    }

    string screenshot()
    {
        return _client.get!string("/screenshot");
    }

    // --- Public accessors ---

    string sessionId()
        => _client.sessionId;

    // --- Package access for Element ---

    package Client client()
        => _client;

    package Element queryElement(LocatorStrategy strategy, string value)
    {
        import selenium.types : WebElement;

        WebElement webElement = _client.post!(WebElement)(
            "/element",
            ElementLocator(strategy, value)
        );
        return new Element(this, webElement);
    }

    package Element[] queryElements(LocatorStrategy strategy, string value)
    {
        import selenium.types : WebElement;

        WebElement[] webElements = _client.post!(WebElement[])(
            "/elements",
            ElementLocator(strategy, value)
        );
        Element[] ret;
        foreach (webElement; webElements)
            ret ~= new Element(this, webElement);
        return ret;
    }

    package Element queryElementFrom(string parentId, LocatorStrategy strategy, string value)
    {
        import selenium.types : WebElement;

        WebElement webElement = _client.post!(WebElement)(
            "/element/"~parentId~"/element",
            ElementLocator(strategy, value)
        );
        return new Element(this, webElement);
    }

    package Element[] queryElementsFrom(string parentId, LocatorStrategy strategy, string value)
    {
        import selenium.types : WebElement;

        WebElement[] webElements = _client.post!(WebElement[])(
            "/element/"~parentId~"/elements",
            ElementLocator(strategy, value)
        );
        Element[] ret;
        foreach (webElement; webElements)
            ret ~= new Element(this, webElement);
        return ret;
    }

private:
    void launch(ushort requestedPort = 0)
    {
        if (_running)
            return;

        port = requestedPort == 0 ? findFreePort() : requestedPort;
        string[] args = ["--port="~port.to!string];

        pid = spawnProcess([executablePath]~args);
        _serverUrl = "http://127.0.0.1:"~port.to!string;

        waitForServer(5000);
        _running = true;
    }

    void createSession(Capabilities desiredCapabilities)
    {
        if (!_running)
            throw new WebDriverConnectionError("Driver is not running.");

        JSONValue payload = JSONValue.emptyObject;
        payload["desiredCapabilities"] = desiredCapabilities.toJSONValue();

        HTTP http = HTTP();
        Response response = send(
            http,
            HTTP.Method.post,
            _serverUrl~"/session",
            payload,
        );

        JSONValue json = parseJSON(cast(string)response.content);
        string sessionId;

        if ("sessionId" in json)
            sessionId = json["sessionId"].str;
        else if ("value" in json && "sessionId" in json["value"])
            sessionId = json["value"]["sessionId"].str;

        _client = new Client(_serverUrl, sessionId);
    }

    ushort findFreePort()
    {
        Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM);
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
        socket.bind(new InternetAddress("127.0.0.1", 0));
        ushort ret = (cast(InternetAddress)socket.localAddress).port;
        socket.close();
        return ret;
    }

    static string tryAutoDetect()
    {
        string[][DriverType] candidates = [
            DriverType.Chrome: ["chromedriver"],
            DriverType.Firefox: ["geckodriver"],
            DriverType.Edge: ["msedgedriver"],
            DriverType.Safari: ["safaridriver"],
        ];

        DriverType[] priority = [
            DriverType.Chrome,
            DriverType.Firefox,
            DriverType.Edge,
            DriverType.Safari,
        ];

        foreach (type; priority)
        {
            foreach (candidate; candidates[type])
            {
                auto result = execute(["which", candidate]);
                if (result.status == 0)
                    return result.output.strip;
            }
        }

        return null;
    }

    static string autoDetectExecutable(DriverType type)
    {
        string[] candidates;
        final switch (type)
        {
            case DriverType.Chrome:
                candidates = ["chromedriver"];
                break;
            case DriverType.Firefox:
                candidates = ["geckodriver"];
                break;
            case DriverType.Edge:
                candidates = ["msedgedriver"];
                break;
            case DriverType.Safari:
                candidates = ["safaridriver"];
                break;
        }

        foreach (candidate; candidates)
        {
            auto result = execute(["which", candidate]);
            if (result.status == 0)
                return result.output.strip;
        }

        throw new WebDriverConnectionError(
            "Could not auto-detect executable for "~type.to!string
        );
    }

    static DriverType inferTypeFromExecutable(string path)
    {
        if (path.canFind("chromedriver"))
            return DriverType.Chrome;
        if (path.canFind("geckodriver"))
            return DriverType.Firefox;
        if (path.canFind("msedgedriver") || path.canFind("edgedriver"))
            return DriverType.Edge;
        if (path.canFind("safaridriver"))
            return DriverType.Safari;

        return DriverType.Chrome;
    }

    void waitForServer(long timeoutMs)
    {
        MonoTime startTime = MonoTime.currTime;

        while ((MonoTime.currTime - startTime).total!"msecs" < timeoutMs)
        {
            try
            {
                HTTP http = HTTP();
                Response response = send(http, HTTP.Method.get, _serverUrl~"/status");
                if (response.status == 200)
                    return;
            }
            catch (Exception)
            {
            }

            Thread.sleep(100.msecs);
        }

        throw new WebDriverConnectionError(
            "WebDriver did not become ready within "~timeoutMs.to!string~" ms"
        );
    }

    static void tryKill(Pid process)
    {
        try
        {
            kill(process);
            wait(process);
        }
        catch (Exception) { }
    }
}
