module selenium.options;

import selenium.log : LogType, wireName;

import conductor.serialize.json : Name;
import std.json : JSONValue;

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

enum AlertBehaviour : string
{
    Accept = "accept",
    Dismiss = "dismiss",
    Ignore = "ignore"
}

struct ChromeOptions
{
    string[] args;
    string binary;
    string[string] prefs;

    bool empty() const
        => args.length == 0 && binary.length == 0 && prefs.length == 0;

    JSONValue toJSONValue() const
    {
        JSONValue ret = JSONValue.emptyObject;
        if (args.length > 0)
        {
            JSONValue arr = JSONValue.emptyArray;
            foreach (a; args)
                arr.array ~= JSONValue(a);
            ret["args"] = arr;
        }
        if (binary.length > 0)
            ret["binary"] = JSONValue(binary);
        if (prefs.length > 0)
        {
            JSONValue obj = JSONValue.emptyObject;
            foreach (k, v; prefs)
                obj[k] = JSONValue(v);
            ret["prefs"] = obj;
        }
        return ret;
    }
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

    ChromeOptions chrome;

    static Options forChrome(string userDataDir = null)
    {
        Options ret;
        ret.browserName = Browser.Chrome;
        if (userDataDir.length > 0)
            ret.chrome.args ~= "--user-data-dir="~userDataDir;
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
            foreach (type; [LogType.Client, LogType.Browser, LogType.Driver, LogType.Performance])
            {
                if (!(logTypes & type))
                    continue;
                string name = wireName(type);
                if (name.length == 0)
                    continue;
                prefs[name] = JSONValue(logLevel);
            }
            ret["loggingPrefs"] = prefs;
            ret["goog:loggingPrefs"] = prefs;
        }
        if (!chrome.empty)
            ret["goog:chromeOptions"] = chrome.toJSONValue();

        return ret;
    }
}
