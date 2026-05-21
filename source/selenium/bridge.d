module selenium.bridge;

import selenium.errors;
import selenium.types;

import conductor.http : Response, send;
import conductor.serialize.json : fromJSON;

import std.conv : to;
import std.json : JSONType, JSONValue, parseJSON;
import std.net.curl : HTTP;
import std.process : kill, Pid, spawnProcess, wait;
import std.socket;
import core.thread : Thread;
import core.time : MonoTime, msecs;

class Bridge
{
public:
    DriverType type;
    string executablePath;
    Pid pid;
    ushort port;
    string serverUrl;
    string sessionId;
    bool running;

    this(DriverType type, string executablePath)
    {
        this.type = type;
        this.executablePath = executablePath;
    }

    void launch(ushort requestedPort = 0)
    {
        if (running)
            return;

        port = requestedPort == 0 ? findFreePort() : requestedPort;
        pid = spawnProcess([executablePath, "--port="~port.to!string]);
        serverUrl = "http://127.0.0.1:"~port.to!string;
        waitForServer(5000);
        running = true;
    }

    void init(Options options)
    {
        if (!running)
            throw new WebDriverConnectionError("Bridge is not running.");

        JSONValue caps = options.toJSONValue();
        JSONValue w3c = JSONValue.emptyObject;
        w3c["alwaysMatch"] = caps;
        JSONValue payload = JSONValue.emptyObject;
        payload["capabilities"] = w3c;
        payload["desiredCapabilities"] = caps;

        HTTP http = HTTP();
        Response response = send(http, HTTP.Method.post, serverUrl~"/session", payload);
        JSONValue json = checkAndParse(response);

        if ("sessionId" in json)
            sessionId = json["sessionId"].str;
        else if ("value" in json && "sessionId" in json["value"])
            sessionId = json["value"]["sessionId"].str;
    }

    void stop()
    {
        if (!running || pid is Pid.init)
            return;

        tryKill(pid);
        running = false;
        pid = Pid.init;
    }

    void disconnect()
    {
        request(HTTP.Method.del, "");
    }

    string[] handles()
        => request!(string[])(HTTP.Method.get, "/window/handles");

    T request(T = JSONValue)(HTTP.Method method, string path)
    {
        HTTP http = HTTP();
        Response response = send(http, method, sessionPath(path));
        JSONValue json = checkAndParse(response);
        static if (is(T == JSONValue))
            return json;
        else
            return parse!T(json);
    }

    T request(T = JSONValue, B)(HTTP.Method method, string path, B body_)
    {
        HTTP http = HTTP();
        Response response = send(http, method, sessionPath(path), body_);
        JSONValue json = checkAndParse(response);
        static if (is(T == JSONValue))
            return json;
        else
            return parse!T(json);
    }

    static string parseElementId(JSONValue json)
    {
        enum W3C_KEY = "element-6066-11e4-a52e-4f735466cecf";
        JSONValue value = ("value" in json) ? json["value"] : json;

        if (value.type == JSONType.object)
        {
            if (W3C_KEY in value && value[W3C_KEY].type == JSONType.string)
                return value[W3C_KEY].str;
            if ("ELEMENT" in value && value["ELEMENT"].type == JSONType.string)
                return value["ELEMENT"].str;
        }

        return null;
    }

    static string[] parseElementIds(JSONValue json)
    {
        JSONValue value = ("value" in json) ? json["value"] : json;
        string[] ret;

        if (value.type == JSONType.array)
        {
            foreach (item; value.array)
                ret ~= parseElementId(item);
        }

        return ret;
    }

private:
    string sessionPath(string path)
        => serverUrl~"/session/"~sessionId~path;

    static T parse(T)(JSONValue json)
    {
        if ("value" in json)
            return fromJSON!T(json["value"]);

        return fromJSON!T(json);
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

    void waitForServer(long timeoutMs)
    {
        MonoTime startTime = MonoTime.currTime;

        while ((MonoTime.currTime - startTime).total!"msecs" < timeoutMs)
        {
            try
            {
                HTTP http = HTTP();
                Response response = send(http, HTTP.Method.get, serverUrl~"/status");
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

    static JSONValue checkAndParse(Response response)
    {
        if (response.content.length == 0)
            return JSONValue.emptyObject;

        JSONValue ret;
        try
            ret = parseJSON(cast(string)response.content);
        catch (Exception)
        {
            if (response.status >= 200 && response.status < 300)
                return JSONValue.emptyObject;

            throw new WebDriverError("Invalid response from server:"~cast(string)response.content);
        }

        if (response.status >= 400)
            throw mapError(response.status, ret);

        return ret;
    }

    static WebDriverError mapError(ushort status, JSONValue json)
    {
        string message = extractMessage(json);

        if ("value" in json && json["value"].type == JSONType.object)
        {
            JSONValue value = json["value"];
            if ("error" in value && value["error"].type == JSONType.string)
            {
                switch (value["error"].str)
                {
                    case "no such element":
                        return new NoSuchElementError(message);
                    case "stale element reference":
                        return new StaleElementReferenceError(message);
                    case "invalid element state":
                        return new InvalidElementStateError(message);
                    case "timeout":
                        return new WebDriverTimeoutError(message);
                    case "session not created":
                        return new WebDriverConnectionError(message);
                    default:
                        return new WebDriverError(message);
                }
            }
        }

        if ("status" in json)
        {
            switch (json["status"].type == JSONType.integer ? json["status"].get!long : 0)
            {
                case 7:
                    return new NoSuchElementError(message);
                case 10:
                    return new StaleElementReferenceError(message);
                case 12:
                    return new InvalidElementStateError(message);
                case 21:
                    return new WebDriverTimeoutError(message);
                case 33:
                    return new WebDriverConnectionError(message);
                default:
                    return new WebDriverError(message);
            }
        }

        return new WebDriverError(message);
    }

    static string extractMessage(JSONValue json)
    {
        if ("value" in json && json["value"].type == JSONType.object)
        {
            JSONValue value = json["value"];
            if ("message" in value && value["message"].type == JSONType.string)
                return value["message"].str;
        }

        if ("message" in json && json["message"].type == JSONType.string)
            return json["message"].str;

        return "WebDriver server error";
    }
}
