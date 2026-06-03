module selenium.options;

import selenium.browser : AlertBehaviour, Browser, defaultBrowser;
import selenium.error : WebDriverConnectionError;

import conductor.serialize.json : Name;
import std.json : JSONValue;
import std.file : isFile;

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
        this.browsers = browsers;
    }

    Browser match()
    {
        bool isValid(Browser browser)
            => browser !is null && browser.executablePath.isFile;

        foreach (browser; browsers)
        {
            if (!browser.generic && isValid(browser))
                return browser;
        }

        foreach (browser; browsers)
        {
            if (browser.generic && isValid(browser))
                return browser;
        }

        if (isValid(defaultBrowser))
            return defaultBrowser;
            
        throw new WebDriverConnectionError("No viable browser was found with valid executable paths.");
    }

    JSONValue toJSONValue() const
    {
        JSONValue alwaysMatch = JSONValue.emptyObject;
        if (platform != Platform.init)
            alwaysMatch["platformName"] = JSONValue(cast(string)platform);
        if (remoteSessionId != null)
            alwaysMatch["webdriver.remote.sessionid"] = JSONValue(remoteSessionId);
        if (remoteQuietExceptions)
            alwaysMatch["webdriver.remote.quietExceptions"] = JSONValue(true);

        JSONValue[] firstMatch;
        bool anyGeneric = false;
        foreach (browser; browsers)
        {
            if (browser.generic)
            {
                anyGeneric = true;
                continue;
            }
            firstMatch ~= browser.toJSONValue();
        }
        if (anyGeneric)
            firstMatch ~= JSONValue.emptyObject;

        JSONValue ret = JSONValue.emptyObject;
        if (alwaysMatch.object.length > 0)
            ret["alwaysMatch"] = alwaysMatch;
        if (firstMatch.length > 0)
            ret["firstMatch"] = JSONValue(firstMatch);

        return ret;
    }
}
