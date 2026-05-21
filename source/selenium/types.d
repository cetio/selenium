module selenium.types;

import selenium.log : LogType, wireName;

import conductor.serialize.json : Name;
import std.json : JSONValue;

enum DriverType
{
    Any,
    Chrome,
    Firefox,
    Edge,
    Safari
}

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

struct Options
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

    LogType logTypes = LogType.None;
    string logLevel = "ALL";

    static Options chrome()
    {
        Options ret;
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
        if (remoteSessionId.length > 0)
            ret["webdriver.remote.sessionid"] = JSONValue(remoteSessionId);
        if (remoteQuietExceptions)
            ret["webdriver.remote.quietExceptions"] = JSONValue(true);
        if (logTypes != LogType.None)
        {
            JSONValue prefs = JSONValue.emptyObject;
            foreach (type; [LogType.Client, LogType.Browser, LogType.Driver, LogType.Performance, LogType.Server])
            {
                if (logTypes & type)
                    prefs[wireName(type)] = JSONValue(logLevel);
            }
            ret["loggingPrefs"] = prefs;
            ret["goog:loggingPrefs"] = prefs;
        }

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