module selenium.browser.firefox;

import selenium.browser : Browser;
import selenium.error : WebDriverError;
import std.json : JSONValue, JSONType;
import std.file : isDir;
import std.regex : match, ctRegex;

class Firefox : Browser
{
    /// Wrapper struct for preferences. Firefox only supports user preferences.
    /// Preferences are NOT sanitized or validated, and are expected to be JSON objects.
    /// Preferences can be found at https://searchfox.org/firefox-main/source/modules/libpref/init/all.js
    struct Preferences
    {
        /// User profile preferences.
        JSONValue user;
    }

    // https://developer.mozilla.org/en-US/docs/Web/WebDriver/Reference/Capabilities/firefoxOptions
    /// Filter for matching a specific browser version.
    string release;
    /// Browser binary. To set a custom binary (ie: Librewolf), set this to the path of the binary.
    string binary;
    /// Arguments to be appended when launching.
    string[] args;
    /// Preferences. These are client preferences for the active profile.
    Preferences prefs;
    /// This is universal for both the recommended `--profile` and the legacy `firefox_profile`.
    /// Must be either a directory path or base-64 archive.
    string profile;

    override string name() const
        => "firefox";

    override JSONValue toJSONValue() const
    {
        JSONValue ret = super.toJSONValue();
        if (release != null)
            ret["browserVersion"] = JSONValue(release);

        JSONValue opts = JSONValue.emptyObject;

        string[] launchArgs = args.dup;
        if (profile != null)
        {
            if (profile.isDir)
                launchArgs ~= "--profile "~profile;
            else if (profile.match(ctRegex!(`^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$`)))
                opts["profile"] = JSONValue(profile);
            else
                throw new WebDriverError("Profile must be a directory path or a base-64 encoded archive.");
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

protected:
    override void parseFrom(JSONValue json)
    {
        super.parseFrom(json);

        if ("browserVersion" in json && json["browserVersion"].type == JSONType.string)
            release = json["browserVersion"].str;

        if ("moz:firefoxOptions" in json)
        {
            JSONValue opts = json["moz:firefoxOptions"];
            if (opts.type != JSONType.object)
                return;

            if ("binary" in opts && opts["binary"].type == JSONType.string)
                binary = opts["binary"].str;

            if ("args" in opts && opts["args"].type == JSONType.array)
            {
                foreach (JSONValue arg; opts["args"].array)
                {
                    if (arg.type == JSONType.string)
                        args ~= arg.str;
                }
            }

            if ("profile" in opts && opts["profile"].type == JSONType.string)
                profile = opts["profile"].str;

            if ("prefs" in opts && opts["prefs"].type == JSONType.object)
                prefs.user = opts["prefs"];
        }
    }
}
