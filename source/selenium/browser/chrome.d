module selenium.browser.chrome;

import selenium.browser : Browser;
import std.json : JSONValue, JSONType;

Chrome defaultChrome;

static this()
{
    defaultChrome = new Chrome();
}

class Chrome : Browser
{
private:
    string _executablePath;

public:
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
    /// Browser binary. To set a custom binary (ie: Vivaldi), set this to the path of the binary.
    string binary;
    /// Command inclusion arguments. To exclude default arguments, see `excludeSwitches`.
    string[] includeSwitches;
    /// Command exclusion arguments.
    string[] excludeSwitches;
    /// Preferences for browser (local state) and user.
    Preferences prefs;
    /// Debugger address. This must be in the format '<hostname/ip:port>', ie: '127.0.0.1:9222'.
    string debuggerAddress;
    /// Minidump path. Only supported for Linux environments.
    /// Setting this on a non-linux compilation will have no effect.
    string minidumpPath;
    /// Detach process from driver.
    /// If true, the browser will not be closed when the driver is closed.
    bool detach;

    string[] extensions;

    // TODO: Support for setting custom names.
    override string name() const
        => "chrome";

    bool addExtension(string extension)
    {
        extensions ~= extension;
        return true;
    }

    override ref string executablePath()
    {
        if (_executablePath.length == 0)
            _executablePath = findExecutable("chromedriver");
        return _executablePath;
    }

    override JSONValue toJSONValue() const
    {
        JSONValue ret = super.toJSONValue();
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

        if (extensions != null)
            opts["extensions"] = JSONValue(extensions);

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
}
