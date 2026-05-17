# 03 — API Design with Specific Examples

## 3.1 Error Hierarchy

### Before (`api.d`)
```d
class SeleniumException : Exception {
    this(string msg, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
        super(msg);
    }

    this(JSONValue data, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null)
    {
        super("Selenium server error: " ~ data["value"]["message"].str);
    }
}
```

### After (`selenium/errors.d`)
```d
module selenium.errors;

import std.exception : basicExceptionCtors;

public:

class WebDriverError : Exception
{
    mixin basicExceptionCtors;
}

class NoSuchElementError : WebDriverError
{
    mixin basicExceptionCtors;
}

class StaleElementReferenceError : WebDriverError
{
    mixin basicExceptionCtors;
}

class InvalidElementStateError : WebDriverError
{
    mixin basicExceptionCtors;
}

class WebDriverTimeoutError : WebDriverError
{
    mixin basicExceptionCtors;
}

class WebDriverConnectionError : WebDriverError
{
    mixin basicExceptionCtors;
}
```

## 3.2 Types and Enums

### Before (`api.d`)
```d
enum Browser: string {
    android = "android",
    chrome = "chrome",
    firefox = "firefox",
    htmlunit = "htmlunit",
    internetExplorer = "internet explorer",
    iPhone = "iPhone",
    iPad = "iPad",
    opera = "opera",
    safari = "safari"
}

struct Capabilities {
    Browser browserName;
    string browserVersion;
    Platform platform;
    // ... 20 fields ...
    @Name("webdriver.remote.sessionid")
    string webdriver_remote_sessionid;

    static Capabilities chrome() {
        Capabilities ret;
        ret.browserName = Browser.chrome;
        return ret;
    }
}
```

### After (`selenium/types.d`)
```d
module selenium.types;

import std.json : JSONValue;
import conductor.serialize.json : Name;

public:

enum Browser : string
{
    Android = "android",
    Chrome = "chrome",
    Firefox = "firefox",
    HtmlUnit = "htmlunit",
    InternetExplorer = "internet explorer",
    IPhone = "iPhone",
    IPad = "iPad",
    Opera = "opera",
    Safari = "safari"
}

enum Platform : string
{
    Windows = "Windows",
    Xp = "Windows XP",
    Vista = "Windows Vista",
    Mac = "Mac",
    Linux = "Linux",
    Unix = "Unix",
    Android = "Android"
}

enum LocatorStrategy : string
{
    ClassName = "class name",
    CssSelector = "css selector",
    Id = "id",
    Name = "name",
    LinkText = "link text",
    PartialLinkText = "partial link text",
    TagName = "tag name",
    XPath = "xpath"
}

enum AlertBehaviour : string
{
    Accept = "accept",
    Dismiss = "dismiss",
    Ignore = "ignore"
}

enum TimeoutType : string
{
    Script = "script",
    Implicit = "implicit",
    PageLoad = "page load"
}

enum MouseButton : int
{
    Left = 0,
    Middle = 1,
    Right = 2
}

enum Orientation : string
{
    Landscape = "LANDSCAPE",
    Portrait = "PORTRAIT"
}

struct Capabilities
{
    Browser browserName;
    string browserVersion;
    Platform platform;
    bool takesScreenshot;
    bool handlesAlerts;
    bool cssSelectorsEnabled;
    bool javascriptEnabled;
    bool databaseEnabled;
    bool locationContextEnabled;
    bool applicationCacheEnabled;
    bool browserConnectionEnabled;
    bool webStorageEnabled;
    bool acceptSslCerts;
    bool rotatable;
    bool nativeEvents;
    AlertBehaviour unexpectedAlertBehaviour;
    int elementScrollBehavior;

    @Name("webdriver.remote.sessionid")
    string remoteSessionId;

    @Name("webdriver.remote.quietExceptions")
    bool remoteQuietExceptions;

    static Capabilities chrome()
    {
        Capabilities ret;
        ret.browserName = Browser.Chrome;
        return ret;
    }

    JSONValue toJSONValue() const
    {
        JSONValue ret = JSONValue.emptyObject;

        if (browserName != Browser.init)
            ret["browserName"] = JSONValue(cast(string)browserName);
        if (browserVersion.length > 0)
            ret["browserVersion"] = JSONValue(browserVersion);
        if (platform != Platform.init)
            ret["platform"] = JSONValue(cast(string)platform);
        if (takesScreenshot)
            ret["takesScreenshot"] = JSONValue(true);
        if (handlesAlerts)
            ret["handlesAlerts"] = JSONValue(true);
        if (cssSelectorsEnabled)
            ret["cssSelectorsEnabled"] = JSONValue(true);
        if (javascriptEnabled)
            ret["javascriptEnabled"] = JSONValue(true);
        if (databaseEnabled)
            ret["databaseEnabled"] = JSONValue(true);
        if (locationContextEnabled)
            ret["locationContextEnabled"] = JSONValue(true);
        if (applicationCacheEnabled)
            ret["applicationCacheEnabled"] = JSONValue(true);
        if (browserConnectionEnabled)
            ret["browserConnectionEnabled"] = JSONValue(true);
        if (webStorageEnabled)
            ret["webStorageEnabled"] = JSONValue(true);
        if (acceptSslCerts)
            ret["acceptSslCerts"] = JSONValue(true);
        if (rotatable)
            ret["rotatable"] = JSONValue(true);
        if (nativeEvents)
            ret["nativeEvents"] = JSONValue(true);
        if (unexpectedAlertBehaviour != AlertBehaviour.init)
            ret["unexpectedAlertBehaviour"] = JSONValue(cast(string)unexpectedAlertBehaviour);
        if (elementScrollBehavior != 0)
            ret["elementScrollBehavior"] = JSONValue(elementScrollBehavior);

        return ret;
    }
}

struct Size
{
    long width;
    long height;
}

struct Position
{
    long x;
    long y;
}

struct Cookie
{
    string name;
    string value;
    string path;
    string domain;
    bool secure;
    bool httpOnly;
    long expiry;
}

struct WebElement
{
    string id;
}

struct GeoLocation(T)
{
    T latitude;
    T longitude;
    T altitude;
}
```

## 3.3 Locators

### Before (`api.d`)
```d
struct ElementLocator {
    LocatorStrategy using;
    string value;
}

ElementLocator classLocator(string name) {
    return ElementLocator(LocatorStrategy.ClassName, name);
}
// ... 7 more ...
```

### After (`selenium/locator.d`)
```d
module selenium.locator;

import selenium.types : LocatorStrategy;

public:

struct ElementLocator
{
    LocatorStrategy strategy;
    string value;
}

ElementLocator byClass(string value)
{
    return ElementLocator(LocatorStrategy.ClassName, value);
}

ElementLocator byCss(string value)
{
    return ElementLocator(LocatorStrategy.CssSelector, value);
}

ElementLocator byId(string value)
{
    return ElementLocator(LocatorStrategy.Id, value);
}

ElementLocator byName(string value)
{
    return ElementLocator(LocatorStrategy.Name, value);
}

ElementLocator byLinkText(string value)
{
    return ElementLocator(LocatorStrategy.LinkText, value);
}

ElementLocator byPartialLinkText(string value)
{
    return ElementLocator(LocatorStrategy.PartialLinkText, value);
}

ElementLocator byTag(string value)
{
    return ElementLocator(LocatorStrategy.TagName, value);
}

ElementLocator byXPath(string value)
{
    return ElementLocator(LocatorStrategy.XPath, value);
}
```

## 3.4 HTTP Protocol Client

### Before (`api.d`)
```d
class SeleniumApiConnector {
    immutable {
        SeleniumApiConnection connection;
        SeleniumApi api;
    }
    // exists only to construct the other two classes
}

class SeleniumApiConnection {
    immutable { string sessionId; string serverUrl; }
    inout {
        void DELETE(T)(string path, T values = null) { ... }
        void POST(T)(string path, T values) { ... }
        auto POST(U, T)(string path, T values) { ... }
        T GET(T)(string path) { ... }
    }
}

class SeleniumApi {
    const SeleniumApiConnection connection;
    inout {
        auto url(string url) { connection.POST("/url", ["url": url]); return this; }
        auto url() { return connection.GET!string("/url"); }
        // ... 80 more methods ...
    }
}
```

### After (`selenium/protocol/client.d`)
```d
module selenium.protocol.client;

import conductor.http : Response, send;
import std.json : JSONValue, parseJSON;
import std.net.curl : HTTP;

import selenium.errors : WebDriverError;
import selenium.protocol.response : checkAndParse;

public:

class Client
{
private:
    string _serverUrl;
    string _sessionId;

public:
    this(string serverUrl, string sessionId)
    {
        _serverUrl = serverUrl;
        _sessionId = sessionId;
    }

    string serverUrl() const
        => _serverUrl;

    string sessionId() const
        => _sessionId;

    void delete_(string path)
    {
        request(HTTP.Method.del, sessionPath(path));
    }

    void delete_(T)(string path, T body_)
    {
        request(HTTP.Method.del, sessionPath(path), body_);
    }

    void post(string path)
    {
        request(HTTP.Method.post, sessionPath(path));
    }

    void post(T)(string path, T body_)
    {
        request(HTTP.Method.post, sessionPath(path), body_);
    }

    T get(T)(string path)
    {
        return parse!T(request(HTTP.Method.get, sessionPath(path)));
    }

    T post(T)(string path)
    {
        return parse!T(request(HTTP.Method.post, sessionPath(path)));
    }

    T post(T, U)(string path, U body_)
    {
        return parse!T(request(HTTP.Method.post, sessionPath(path), body_));
    }

    void disconnect()
    {
        delete_("/");
    }

private:
    string sessionPath(string path)
    {
        return _serverUrl ~ "/session/" ~ _sessionId ~ path;
    }

    JSONValue request(HTTP.Method method, string url)
    {
        HTTP http = HTTP();
        Response response = send(http, method, url);
        return checkAndParse(response);
    }

    JSONValue request(T)(HTTP.Method method, string url, T body_)
    {
        HTTP http = HTTP();
        Response response = send(http, method, url, body_);
        return checkAndParse(response);
    }

    static T parse(T)(JSONValue json)
    {
        import conductor.serialize.json : fromJSON;

        return fromJSON!T(json["value"]);
    }
}
```

## 3.5 Unified Driver

The `Driver` class merges process management (from old `driver.d`) and session operations (from old `session.d`), following Ruby's pattern where `Driver` is the single user-facing object.

### After (`selenium/driver.d`)
```d
module selenium.driver;

import conductor.http : Response, send;
import std.algorithm.searching : canFind;
import std.conv : to;
import std.json : JSONValue;
import std.net.curl : HTTP;
import std.process : execute, Pid, spawnProcess;
import std.socket : AddressFamily, InternetAddress, Socket, SocketOption, SocketOptionLevel, SocketType;
import std.string : strip;
import core.thread : Thread;
import core.time : MonoTime, msecs;

import selenium.errors : WebDriverConnectionError;
import selenium.element : Element;
import selenium.locator : ElementLocator;
import selenium.protocol.client : Client;
import selenium.types : Capabilities, LocatorStrategy, Size;

public:

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
    DriverType _type;
    string _executablePath;
    Pid _pid;
    string _serverUrl;
    ushort _port;
    bool _running;
    Client _client;

private:
    this(DriverType type, string executablePath)
    {
        _type = type;
        _executablePath = executablePath;
    }

public:
    // --- Factory methods (preferred entry points) ---

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
        if (!_running || _pid is Pid.init)
            return;

        tryKill(_pid);
        _running = false;
        _pid = Pid.init;
    }

    bool running() const
        => _running;

    string serverUrl() const
        => _serverUrl;

    // --- Session lifecycle ---

    void quit()
    {
        if (_client !is null)
            _client.disconnect();

        stop();
    }

    // --- Navigation ---

    string url()
    {
        return _client.get!string("/url");
    }

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
    {
        return _client.get!string("/title");
    }

    string source()
    {
        return _client.get!string("/source");
    }

    // --- Window / Frame ---

    string windowHandle()
    {
        return _client.get!string("/window");
    }

    void window(string handle)
    {
        _client.post("/window", ["handle": handle]);
    }

    string[] windowHandles()
    {
        return _client.get!(string[])("/window/handles");
    }

    void closeWindow()
    {
        _client.delete_("/window");
    }

    void maximize()
    {
        _client.post("/window/maximize");
    }

    Size windowSize()
    {
        return _client.get!Size("/window/rect");
    }

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
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return queryElement(LocatorOf!strategy, value);
    }

    Element findOne(ElementLocator locator)
    {
        return queryElement(locator.strategy, locator.value);
    }

    Element[] findMany(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
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

    T execute(T = string)(string script, JSONValue args = JSONValue.emptyArray)
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
        return new Element(this, webElement, cast(string)strategy, value);
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
            ret ~= new Element(this, webElement, cast(string)strategy, value);
        return ret;
    }

    package Element queryElementFrom(string parentId, LocatorStrategy strategy, string value)
    {
        import selenium.types : WebElement;

        WebElement webElement = _client.post!(WebElement)(
            "/element/" ~ parentId ~ "/element",
            ElementLocator(strategy, value)
        );
        return new Element(this, webElement, cast(string)strategy, value);
    }

    package Element[] queryElementsFrom(string parentId, LocatorStrategy strategy, string value)
    {
        import selenium.types : WebElement;

        WebElement[] webElements = _client.post!(WebElement[])(
            "/element/" ~ parentId ~ "/elements",
            ElementLocator(strategy, value)
        );
        Element[] ret;
        foreach (webElement; webElements)
            ret ~= new Element(this, webElement, cast(string)strategy, value);
        return ret;
    }

private:
    void launch(ushort requestedPort = 0)
    {
        if (_running)
            return;

        _port = requestedPort == 0 ? findFreePort() : requestedPort;
        string[] args = ["--port=" ~ _port.to!string];

        _pid = spawnProcess([_executablePath] ~ args);
        _serverUrl = "http://127.0.0.1:" ~ _port.to!string;

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
            _serverUrl ~ "/session",
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
            "Could not auto-detect executable for " ~ type.to!string
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
                Response response = send(http, HTTP.Method.get, _serverUrl ~ "/status");
                if (response.status == 200)
                    return;
            }
            catch (Exception)
            {
            }

            Thread.sleep(100.msecs);
        }

        throw new WebDriverConnectionError(
            "WebDriver did not become ready within " ~ timeoutMs.to!string ~ " ms"
        );
    }

    static void tryKill(Pid process)
    {
        try
        {
            std.process.kill(process);
            std.process.wait(process);
        }
        catch (Exception)
        {
        }
    }
}
```

## 3.6 Element with SearchContext

`Element` exposes both property operations and scoped element search, following Ruby's `SearchContext` mixin pattern.

### Before (`session.d`)
```d
class Element
{
    alias opEquals = Object.opEquals;
    private immutable { SeleniumApi api; WebElement element; }
    this(immutable SeleniumApi api, immutable WebElement element) immutable { ... }

    inout {
        immutable(Element) findOne(ElementLocator locator) { ... }
        inout(Element) click() { api.clickElement(element.ELEMENT); return this; }
        @property {
            string text() { return api.elementText(element.ELEMENT); }
            bool isEnabled() { return api.elementSelected(element.ELEMENT); } // BUG!
        }
    }
}
```

### After (`selenium/element.d`)
```d
module selenium.element;

import selenium.driver : Driver;
import selenium.locator : ElementLocator;
import selenium.types : LocatorStrategy, Position, Size, WebElement;

public:

class Element
{
private:
    Driver _driver;
    WebElement _webElement;
    string _strategy;
    string _value;

public:
    this(Driver driver, WebElement webElement, string strategy = null, string value = null)
    {
        _driver = driver;
        _webElement = webElement;
        _strategy = strategy;
        _value = value;
    }

    string id() const
        => _webElement.id;

    // --- Search context (scoped to this element) ---

    Element findOne(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return _driver.queryElementFrom(_webElement.id, LocatorOf!strategy, value);
    }

    Element findOne(ElementLocator locator)
    {
        return _driver.queryElementFrom(
            _webElement.id,
            locator.strategy,
            locator.value
        );
    }

    Element[] findMany(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return _driver.queryElementsFrom(_webElement.id, LocatorOf!strategy, value);
    }

    Element[] findMany(ElementLocator locator)
    {
        return _driver.queryElementsFrom(
            _webElement.id,
            locator.strategy,
            locator.value
        );
    }

    // --- Properties ---

    string text()
    {
        return _driver.client.get!string(elementPath("/text"));
    }

    string tagName()
    {
        return _driver.client.get!string(elementPath("/name"));
    }

    void click()
    {
        _driver.client.post(elementPath("/click"));
    }

    void submit()
    {
        _driver.client.post(elementPath("/submit"));
    }

    void sendKeys(string[] keys)
    {
        _driver.client.post(elementPath("/value"), ["value": keys]);
    }

    void sendKeys(string keys)
    {
        sendKeys([keys]);
    }

    void clear()
    {
        _driver.client.post(elementPath("/clear"));
    }

    bool selected()
    {
        return _driver.client.get!bool(elementPath("/selected"));
    }

    bool enabled()
    {
        return _driver.client.get!bool(elementPath("/enabled"));
    }

    bool displayed()
    {
        return _driver.client.get!bool(elementPath("/displayed"));
    }

    string attribute(string name)
    {
        return _driver.client.get!string(elementPath("/attribute/" ~ name));
    }

    string cssValue(string property)
    {
        return _driver.client.get!string(elementPath("/css/" ~ property));
    }

    Position position()
    {
        return _driver.client.get!Position(elementPath("/location"));
    }

    Position positionInView()
    {
        return _driver.client.get!Position(elementPath("/location_in_view"));
    }

    Size size()
    {
        return _driver.client.get!Size(elementPath("/size"));
    }

    string screenshot()
    {
        return _driver.client.get!string(elementPath("/screenshot"));
    }

private:
    string elementPath(string suffix)
    {
        return "/element/" ~ _webElement.id ~ suffix;
    }
}
```

### Fixes Applied
- Removed `immutable class Element`
- Removed `alias opEquals = Object.opEquals` (unnecessary)
- Removed `@property` blocks; accessors use lambda syntax
- **Fixed bug**: old `isEnabled()` called `elementSelected` instead of `elementEnabled`
- `isSelected()` / `isEnabled()` / `isDisplayed()` -> `selected()` / `enabled()` / `displayed()` (UFCS-friendly)
- `elementPath` helper eliminates path repetition
- `Element` holds `Driver` reference, not raw `Client` (allows scoped search and server access)

## 3.7 Page Objects (Replacing `workflow.d`)

### Before (`workflow.d`)
```d
abstract class SeleniumPage {
    protected { immutable SeleniumSession session; }
    this(immutable SeleniumSession session) { this.session = session; }
    abstract bool isPresent();
}

class Workflow(T, U) { ... complex template soup ... }
```

### After (`selenium/page.d`)
```d
module selenium.page;

import core.time : Duration, seconds;
import selenium.driver : Driver;
import selenium.element : Element;
import selenium.locator : ElementLocator;

public:

abstract class Page
{
private:
    Driver _driver;

public:
    this(Driver driver)
    {
        _driver = driver;
    }

    Driver driver()
        => _driver;

    abstract bool isPresent();

    void waitFor(Duration timeout = 10.seconds)
    {
        import core.time : MonoTime, msecs;

        MonoTime deadline = MonoTime.currTime + timeout;
        while (MonoTime.currTime < deadline)
        {
            if (isPresent())
                return;

            Thread.sleep(100.msecs);
        }

        import selenium.errors : WebDriverTimeoutError;

        throw new WebDriverTimeoutError(
            "Page did not become present within " ~ timeout.to!string
        );
    }

    Element findOne(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return _driver.findOne!strategy(value);
    }

    Element[] findMany(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return _driver.findMany!strategy(value);
    }
}
```

## 3.8 Package Root

### After (`selenium/package.d`)
```d
module selenium;

public:

public import selenium.driver;
public import selenium.element;
public import selenium.errors;
public import selenium.locator;
public import selenium.page;
public import selenium.protocol;
public import selenium.types;
```

### After (`selenium/protocol/package.d`)
```d
module selenium.protocol;

public:

public import selenium.protocol.client;
public import selenium.protocol.response;
```

## 3.9 Usage Comparison

### Before
```d
SeleniumDriver driver = new SeleniumDriver(DriverType.Chrome, "/path/to/chromedriver");
driver.start();

immutable SeleniumSession session = driver.newSession(Capabilities.chrome);
scope(exit) session.close();

session.navigation.url("http://example.com");
assert(session.navigation.url == "https://example.com/");

immutable Element heading = session.findOne(tagLocator("h1"));
assert(heading.text == "Example Domain");
```

### After
```d
// Zero-config: auto-detects Chrome, finds chromedriver, launches, creates session
Driver driver = Driver.start();
scope(exit) driver.quit();

driver.url("http://example.com");
assert(driver.url == "https://example.com/");

Element heading = driver.findOne!"tag"("h1");
assert(heading.text == "Example Domain");

// Scoped search on element
Element link = heading.findOne!"linkText"("More information...");
link.click();
```
