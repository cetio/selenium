module selenium.browser.firefox;

import selenium.browser : Browser;
import std.json : JSONValue;

Firefox defaultFirefox;

static this()
{
    defaultFirefox = new Firefox();
}

class Firefox : Browser
{
private:
    string _executablePath;

public:
    // https://developer.mozilla.org/en-US/docs/Web/WebDriver/Reference/Capabilities/firefoxOptions
    /// Browser binary. To set a custom binary (ie: Librewolf), set this to the path of the binary.
    string binary;
    /// Arguments to be appended when launching.
    string[] args;
    /// Preferences. These are client preferences for the active profile.
    string[string] prefs;
    /// This is universal for both the recommended `--profile` and the legacy `firefox_profile`.
    /// This should be a directory path containing a Firefox profile, but Base-64 Zip is supported for compatibility.
    string profile;

    override string name() const
        => "firefox";

    override ref string executablePath()
    {
        if (_executablePath.length == 0)
            _executablePath = findExecutable("geckodriver");
        return _executablePath;
    }

    override JSONValue toJSONValue() const
    {
        JSONValue ret = super.toJSONValue();
        JSONValue chromeOpts = JSONValue.emptyObject;
        if (args.length > 0)
        {
            JSONValue arr = JSONValue.emptyArray;
            foreach (arg; args)
                arr.array ~= JSONValue(arg);
            chromeOpts["args"] = arr;
        }

        if (binary.length > 0)
            chromeOpts["binary"] = JSONValue(binary);

        if (prefs.length > 0)
        {
            JSONValue obj = JSONValue.emptyObject;
            foreach (key, value; prefs)
                obj[key] = JSONValue(value);
            chromeOpts["prefs"] = obj;
        }

        if (chromeOpts.object.length > 0)
            ret["moz:firefoxOptions"] = chromeOpts;

        return ret;
    }
}
