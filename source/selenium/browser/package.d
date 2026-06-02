module selenium.browser;

import std.json : JSONValue;

enum AlertBehaviour : string
{
    Accept = "accept",
    Dismiss = "dismiss",
    Ignore = "ignore"
}

class Browser
{
    string browserVersion;
    bool takesScreenshot;
    bool handlesAlerts;
    bool cssSelectorsEnabled;
    bool javascriptEnabled;
    bool databaseEnabled;
    bool locationContextEnabled;
    bool applicationCacheEnabled;
    bool browserConnectionEnabled;
    bool webStorageEnabled;
    bool acceptSslCerts;
    bool rotatable;
    bool nativeEvents;
    AlertBehaviour unexpectedAlertBehaviour;
    int elementScrollBehavior;

    string name() const
    {
        return "";
    }

    bool generic() const
    {
        return name.length == 0;
    }

    JSONValue toJSONValue() const
    {
        JSONValue ret = JSONValue.emptyObject;
        if (name.length > 0)
            ret["browserName"] = JSONValue(name);
        if (browserVersion.length > 0)
            ret["browserVersion"] = JSONValue(browserVersion);
        if (takesScreenshot)
            ret["takesScreenshot"] = JSONValue(true);
        if (handlesAlerts)
            ret["handlesAlerts"] = JSONValue(true);
        if (cssSelectorsEnabled)
            ret["cssSelectorsEnabled"] = JSONValue(true);
        if (javascriptEnabled)
            ret["javascriptEnabled"] = JSONValue(true);
        if (databaseEnabled)
            ret["databaseEnabled"] = JSONValue(true);
        if (locationContextEnabled)
            ret["locationContextEnabled"] = JSONValue(true);
        if (applicationCacheEnabled)
            ret["applicationCacheEnabled"] = JSONValue(true);
        if (browserConnectionEnabled)
            ret["browserConnectionEnabled"] = JSONValue(true);
        if (webStorageEnabled)
            ret["webStorageEnabled"] = JSONValue(true);
        if (acceptSslCerts)
            ret["acceptSslCerts"] = JSONValue(true);
        if (rotatable)
            ret["rotatable"] = JSONValue(true);
        if (nativeEvents)
            ret["nativeEvents"] = JSONValue(true);
        if (unexpectedAlertBehaviour != AlertBehaviour.init)
            ret["unexpectedAlertBehaviour"] = JSONValue(cast(string)unexpectedAlertBehaviour);
        if (elementScrollBehavior != 0)
            ret["elementScrollBehavior"] = JSONValue(elementScrollBehavior);
        return ret;
    }
}
