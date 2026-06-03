module selenium.browser.firefox;

import selenium.browser : Browser;
import selenium.error : WebDriverError;
import std.json : JSONValue, JSONType;
import std.file : isDir;
import std.regex : match, ctRegex;

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
    /// Wrapper struct for preferences. Firefox only supports user preferences.
    /// Preferences are NOT sanitized or validated, and are expected to be JSON objects.
    /// Preferences can be found at https://searchfox.org/firefox-main/source/modules/libpref/init/all.js
    struct Preferences
    {
        /// User profile preferences.
        JSONValue user;
    }

    // https://developer.mozilla.org/en-US/docs/Web/WebDriver/Reference/Capabilities/firefoxOptions
    /// Browser binary. To set a custom binary (ie: Librewolf), set this to the path of the binary.
    string binary;
    /// Arguments to be appended when launching.
    string[] args;
    /// Preferences. These are client preferences for the active profile.
    Preferences prefs;
    /// This is universal for both the recommended `--profile` and the legacy `firefox_profile`.
    /// This should be a directory path containing a Firefox profile, but Base-64 Zip is supported for compatibility.
    string profile;

    override string name() const
        => "firefox";

    override ref string executablePath()
    {
        if (_executablePath == null)
            _executablePath = findExecutable("geckodriver");
        return _executablePath;
    }

    override JSONValue toJSONValue() const
    {
        JSONValue ret = super.toJSONValue();
        JSONValue opts = JSONValue.emptyObject;

        string[] launchArgs = args.dup;
        if (profile != null)
        {
            if (profile.isDir)
                launchArgs ~= "--profile " ~ profile;
            else if (profile.match(ctRegex!(`^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$`)))
                opts["profile"] = JSONValue(profile);
            else
                throw new WebDriverError("Profile must be a directory path or a base-64 encoded zip file.");
        }
        if (launchArgs != null)
            opts["args"] = JSONValue(launchArgs);

        if (binary != null)
            opts["binary"] = JSONValue(binary);

        if (prefs.user.type == JSONType.object && prefs.user.object.length > 0)
            opts["prefs"] = prefs.user;

        if (opts.object.length > 0)
            ret["moz:firefoxOptions"] = opts;

        return ret;
    }
}
