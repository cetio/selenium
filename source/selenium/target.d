module selenium.target;

import selenium.browser : Browser, defaultBrowser, Timeouts;
import selenium.error : WebDriverConnectionError;

import std.json : JSONValue;
import std.file : isFile;

enum Platform : string
{
    Any = "",
    Windows = "Windows",
    Linux = "Linux",
    Mac = "Mac",
    Android = "Android"
}

class Target
{
    Platform platform;
    Browser[] browsers;

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
