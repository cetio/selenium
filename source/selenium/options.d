module selenium.options;

import selenium.browser : AlertBehaviour, Browser, defaultBrowser;
import selenium.browser.chrome : Chrome, defaultChrome;

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
