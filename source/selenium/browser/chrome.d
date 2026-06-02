module selenium.browser.chrome;

import selenium.browser : Browser;
import std.json : JSONValue;
import std.string : strip;
import std.typecons : Tuple;
static import std.process;

Chrome defaultChrome;

static this()
{
    defaultChrome = new Chrome();
}

class Chrome : Browser
{
    private string _executablePath;
    string[] args;
    string binary;
    string[string] prefs;

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
        if (chromeOpts.object.length > 0)
            ret["goog:chromeOptions"] = chromeOpts;
        return ret;
    }
}
