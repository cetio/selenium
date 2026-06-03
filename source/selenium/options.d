module selenium.options;

import selenium.browser : Browser, defaultBrowser;
import selenium.error : WebDriverConnectionError;

import std.json : JSONValue;
import std.file : isFile;

struct Options
{
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
        if (firstMatch.length > 0)
            ret["firstMatch"] = JSONValue(firstMatch);

        return ret;
    }
}
