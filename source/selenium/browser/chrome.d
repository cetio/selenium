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
    private string _executablePath;
public:
    string[string] prefs;
    string[] extensions;
    string[] excludeSwitches;
    string debuggerAddress;
    string minidumpPath;
    bool detach;

    override string name() const
        => "chrome";

    override ref string executablePath()
    {
        if (_executablePath.length == 0)
            _executablePath = findExecutable("chromedriver");
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

        if (extensions.length > 0)
        {
            JSONValue arr = JSONValue.emptyArray;
            foreach (ext; extensions)
                arr.array ~= JSONValue(ext);
            chromeOpts["extensions"] = arr;
        }

        if (excludeSwitches.length > 0)
        {
            JSONValue arr = JSONValue.emptyArray;
            foreach (eachSwitch; excludeSwitches)
                arr.array ~= JSONValue(eachSwitch);
            chromeOpts["excludeSwitches"] = arr;
        }

        if (debuggerAddress.length > 0)
            chromeOpts["debuggerAddress"] = JSONValue(debuggerAddress);

        if (minidumpPath.length > 0)
            chromeOpts["minidumpPath"] = JSONValue(minidumpPath);

        if (detach)
            chromeOpts["detach"] = JSONValue(true);

        if (chromeOpts.object.length > 0)
            ret["goog:chromeOptions"] = chromeOpts;

        return ret;
    }
}
