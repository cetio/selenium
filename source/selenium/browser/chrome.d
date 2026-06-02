module selenium.browser.chrome;

import selenium.browser : Browser;

import std.json : JSONValue;

class Chrome : Browser
{
    string[] args;
    string binary;
    string[string] prefs;

    override string name() const
        => "chrome";

    override JSONValue toJSONValue() const
    {
        JSONValue ret = super.toJSONValue();
        JSONValue chromeOpts = JSONValue.emptyObject;
        if (args.length > 0)
        {
            JSONValue arr = JSONValue.emptyArray;
            foreach (a; args)
                arr.array ~= JSONValue(a);
            chromeOpts["args"] = arr;
        }
        if (binary.length > 0)
            chromeOpts["binary"] = JSONValue(binary);
        if (prefs.length > 0)
        {
            JSONValue obj = JSONValue.emptyObject;
            foreach (k, v; prefs)
                obj[k] = JSONValue(v);
            chromeOpts["prefs"] = obj;
        }
        if (chromeOpts.object.length > 0)
            ret["goog:chromeOptions"] = chromeOpts;
        return ret;
    }
}
