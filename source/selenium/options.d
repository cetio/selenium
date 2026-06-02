module selenium.options;

import selenium.browser : AlertBehaviour, Browser, defaultBrowser;
import selenium.browser.chrome : Chrome, defaultChrome;
import selenium.log : LogType, wireName;

import conductor.serialize.json : Name;
import std.json : JSONValue;

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

struct Options
{
    Platform platform;
    Browser[] browsers;

    @Name("webdriver.remote.sessionid")
    string remoteSessionId;

    @Name("webdriver.remote.quietExceptions")
    bool remoteQuietExceptions;

    LogType logTypes = LogType.None;
    string logLevel = "ALL";

    this(Browser[] browsers...)
    {
        if (browsers.length > 0)
            this.browsers = browsers;
        else
            this.browsers = [defaultBrowser];
    }

    JSONValue toJSONValue() const
    {
        JSONValue alwaysMatch = JSONValue.emptyObject;
        if (platform != Platform.init)
            alwaysMatch["platformName"] = JSONValue(cast(string)platform);
        if (remoteSessionId.length > 0)
            alwaysMatch["webdriver.remote.sessionid"] = JSONValue(remoteSessionId);
        if (remoteQuietExceptions)
            alwaysMatch["webdriver.remote.quietExceptions"] = JSONValue(true);
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
            alwaysMatch["loggingPrefs"] = prefs;
            alwaysMatch["goog:loggingPrefs"] = prefs;
        }

        JSONValue firstMatch = JSONValue.emptyArray;
        bool anyGeneric = false;
        foreach (browser; browsers)
        {
            if (browser.generic)
            {
                anyGeneric = true;
                continue;
            }
            firstMatch.array ~= browser.toJSONValue();
        }
        if (anyGeneric)
            firstMatch.array ~= JSONValue.emptyObject;

        JSONValue capabilities = JSONValue.emptyObject;
        if (alwaysMatch.object.length > 0)
            capabilities["alwaysMatch"] = alwaysMatch;
        if (firstMatch.array.length > 0)
            capabilities["firstMatch"] = firstMatch;

        return capabilities;
    }
}
