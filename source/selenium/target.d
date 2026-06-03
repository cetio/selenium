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
    // TODO: `defaultX` needs to be removed.
    Browser alwaysMatch = new Browser();
    Browser[] firstMatch;

    this(Browser[] firstMatch...)
    {
        this.firstMatch = firstMatch;
    }

    Browser match()
    {
        bool isValid(Browser browser)
            => browser !is null && browser.executablePath.isFile;

        foreach (browser; firstMatch)
        {
            if (isValid(browser))
                return browser;
        }

        if (isValid(alwaysMatch))
            return alwaysMatch;

        throw new WebDriverConnectionError("No viable browser was found with valid executable paths.");
    }

    JSONValue toJSONValue() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["alwaysMatch"] = alwaysMatch.toJSONValue();
        if (platform != Platform.Any)
            ret["alwaysMatch"]["platformName"] = JSONValue(cast(string)platform);

        JSONValue[] firstMatchJson;
        foreach (browser; firstMatch)
            firstMatchJson ~= browser.toJSONValue();
        if (firstMatchJson.length > 0)
            ret["firstMatch"] = JSONValue(firstMatchJson);

        return ret;
    }
}
