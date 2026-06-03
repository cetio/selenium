module selenium.browser;

import std.json : JSONValue;
import std.string : strip;
import std.typecons : Tuple;
static import std.process;

import core.time : Duration;

Browser defaultBrowser;

static this()
{
    defaultBrowser = new Browser();
}

enum AlertBehaviour : string
{
    Accept = "accept",
    Dismiss = "dismiss",
    Ignore = "ignore"
}

class Browser
{
private:
    string _executablePath;
    
public:
    string release;
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
    Duration implicitTimeout;
    Duration pageTimeout;
    Duration scriptTimeout;

    string name() const
        => "";

    bool generic() const
        => name.length == 0;

    ref string executablePath()
    {
        if (_executablePath.length == 0)
        {
            foreach (candidate; ["chromedriver", "msedgedriver", "safaridriver", "geckodriver"])
            {
                string path = findExecutable(candidate);
                if (path.length > 0)
                {
                    _executablePath = path;
                    break;
                }
            }
        }
        return _executablePath;
    }


    JSONValue toJSONValue() const
    {
        JSONValue ret = JSONValue.emptyObject;
        if (name.length > 0)
            ret["browserName"] = JSONValue(name);
        if (release.length > 0)
            ret["browserVersion"] = JSONValue(release);
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

package:
    static string findExecutable(string candidate)
    {
        Tuple!(int, "status", string, "output") result =
            std.process.execute(["which", candidate]);
        if (result.status == 0)
            return result.output.strip;
        return null;
    }
}
