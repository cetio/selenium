module selenium.browser.chrome;

import selenium.browser : Browser;
import std.json : JSONValue;

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
    struct Preferences
    {
        /// Local state preferences.
        string[string] browser;
        /// User profile preferences.
        string[string] user;
    }

    // https://developer.chrome.com/docs/chromedriver/capabilities#chromeoptions_object
    /// Browser binary. To set a custom binary (ie: Vivaldi), set this to the path of the binary.
    string binary;
    /// Arguments to be appended when launching. To exclude initial arguments, see `excludeSwitches`.
    string[] args;
    /// Preferences for browser (local state) and user.
    Preferences prefs;
    /// Switch exclusions. All included switches will be excluded from the default binary arguments.
    string[] excludeSwitches;
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
        if (args.length > 0)
        {
            JSONValue arr = JSONValue.emptyArray;
            foreach (arg; args)
                arr.array ~= JSONValue(arg);
            opts["args"] = arr;
        }

        if (binary.length > 0)
            opts["binary"] = JSONValue(binary);

        if (prefs.length > 0)
        {
            JSONValue obj = JSONValue.emptyObject;
            foreach (key, value; prefs)
                obj[key] = JSONValue(value);
            opts["prefs"] = obj;
        }

        if (extensions.length > 0)
        {
            JSONValue arr = JSONValue.emptyArray;
            foreach (ext; extensions)
                arr.array ~= JSONValue(ext);
            opts["extensions"] = arr;
        }

        if (excludeSwitches.length > 0)
        {
            JSONValue arr = JSONValue.emptyArray;
            foreach (eachSwitch; excludeSwitches)
                arr.array ~= JSONValue(eachSwitch);
            opts["excludeSwitches"] = arr;
        }

        if (debuggerAddress.length > 0)
            opts["debuggerAddress"] = JSONValue(debuggerAddress);

        version (linux)
        {
            if (minidumpPath.length > 0)
                opts["minidumpPath"] = JSONValue(minidumpPath);
        }

        if (detach)
            opts["detach"] = JSONValue(true);

        if (opts.object.length > 0)
            ret["goog:chromeOptions"] = opts;

        return ret;
    }
}
