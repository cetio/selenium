module selenium.browser.chrome;

import selenium.browser : Browser;
import selenium.error : WebDriverError;
import std.json : JSONValue, JSONType;
import std.base64 : Base64;
import std.file : read, isFile;
import std.regex : match, ctRegex;

class Chrome : Browser
{
    /// Wrapper struct for preferences. Chrome supports both browser (local state) and user preferences.
    /// Preferences are NOT sanitized or validated, and are expected to be JSON arrays.
    struct Preferences
    {
        /// Local state preferences.
        JSONValue browser;
        /// User profile preferences.
        JSONValue user;
    }

    // https://developer.chrome.com/docs/chromedriver/capabilities#chromeoptions_object
    /// Filter for matching a specific browser version.
    string release;
    /// Browser binary. To set a custom binary (ie: Vivaldi), set this to the path of the binary.
    string binary;
    /// Command inclusion arguments. To exclude default arguments, see `excludeSwitches`.
    string[] includeSwitches;
    /// Command exclusion arguments.
    string[] excludeSwitches;
    /// Preferences for browser (local state) and user.
    Preferences prefs;
    /// Debugger address. Must be in the format '<hostname/ip:port>', ie: '127.0.0.1:9222'.
    string debuggerAddress;
    /// Minidump path. Only supported for Linux environments.
    /// Setting this on a non-linux compilation will have no effect.
    string minidumpPath;
    /// Detach process from driver.
    /// If true, the browser will not be closed when the driver is closed.
    bool detach;
    /// Extensions to load. May be provided as either base-64 encoded CRX content or a path to a CRX file.
    string[] extensions;

    // TODO: Support for setting custom names.
    override string name() const
        => "chrome";

    override JSONValue toJSON() const
    {
        JSONValue ret = super.toJSON();
        if (release != null)
            ret["browserVersion"] = JSONValue(release);
            
        JSONValue opts = JSONValue.emptyObject;
        if (includeSwitches != null)
            opts["args"] = JSONValue(includeSwitches);
        
        if (excludeSwitches != null)
            opts["excludeSwitches"] = JSONValue(excludeSwitches);

        if (binary != null)
            opts["binary"] = JSONValue(binary);

        if (prefs.browser.type == JSONType.object && prefs.browser.object.length > 0)
            opts["localState"] = prefs.browser;
        
        if (prefs.user.type == JSONType.object && prefs.user.object.length > 0)
            opts["prefs"] = prefs.user;

        foreach (ext; extensions)
        {
            if (ext.isFile)
                opts["extensions"] ~= JSONValue(cast(string)Base64.encode(cast(ubyte[])read(ext)));
            else if (ext.match(ctRegex!(`^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$`)))
                opts["extensions"] ~= JSONValue(ext);
            else
                throw new WebDriverError("Extension must be a file path or a base-64 encoded CRX content.");
        }

        if (debuggerAddress != null)
            opts["debuggerAddress"] = JSONValue(debuggerAddress);

        version (linux)
        {
            if (minidumpPath != null)
                opts["minidumpPath"] = JSONValue(minidumpPath);
        }

        if (detach)
            opts["detach"] = JSONValue(true);

        if (opts.object.length > 0)
            ret["goog:chromeOptions"] = opts;

        return ret;
    }

protected:
    override void parseFrom(JSONValue value)
    {
        super.parseFrom(value);

        if ("browserVersion" in value && value["browserVersion"].type == JSONType.string)
            release = value["browserVersion"].str;

        if ("goog:chromeOptions" in value)
        {
            JSONValue opts = value["goog:chromeOptions"];
            if (opts.type != JSONType.object)
                return;

            if ("binary" in opts && opts["binary"].type == JSONType.string)
                binary = opts["binary"].str;

            if ("args" in opts && opts["args"].type == JSONType.array)
            {
                foreach (JSONValue arg; opts["args"].array)
                {
                    if (arg.type == JSONType.string)
                        includeSwitches ~= arg.str;
                }
            }

            if ("excludeSwitches" in opts && opts["excludeSwitches"].type == JSONType.array)
            {
                foreach (JSONValue sw; opts["excludeSwitches"].array)
                {
                    if (sw.type == JSONType.string)
                        excludeSwitches ~= sw.str;
                }
            }

            if ("localState" in opts && opts["localState"].type == JSONType.object)
                prefs.browser = opts["localState"];

            if ("prefs" in opts && opts["prefs"].type == JSONType.object)
                prefs.user = opts["prefs"];

            if ("debuggerAddress" in opts && opts["debuggerAddress"].type == JSONType.string)
                debuggerAddress = opts["debuggerAddress"].str;

            version (linux)
            {
                if ("minidumpPath" in opts && opts["minidumpPath"].type == JSONType.string)
                    minidumpPath = opts["minidumpPath"].str;
            }

            if ("detach" in opts && opts["detach"].type == JSONType.true_)
                detach = true;
            else if ("detach" in opts && opts["detach"].type == JSONType.false_)
                detach = false;

            if ("extensions" in opts && opts["extensions"].type == JSONType.array)
            {
                foreach (JSONValue ext; opts["extensions"].array)
                {
                    if (ext.type == JSONType.string)
                        extensions ~= ext.str;
                }
            }
        }
    }
}
