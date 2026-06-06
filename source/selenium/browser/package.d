module selenium.browser;

import selenium.error : InvalidArgumentError, WebDriverConnectionError;

import std.json : JSONValue, JSONType;
import std.typecons : Tuple;
import std.string : strip;
static import std.process;
import core.time : Duration, dur;

enum PageLoadStrategy : string
{
    Normal = "normal",
    Eager = "eager",
    None = "none"
}

enum UnhandledPromptBehavior : string
{
    Dismiss = "dismiss",
    Accept = "accept",
    DismissAndNotify = "dismiss and notify",
    AcceptAndNotify = "accept and notify",
    Ignore = "ignore"
}

enum Platform : string
{
    Any = "",
    Windows = "Windows",
    Linux = "Linux",
    Mac = "Mac",
    Android = "Android"
}

struct Timeouts
{
    /// Time to wait for an element to exist when locating.
    Duration implicit;
    /// Time to wait for page navigation to complete.
    Duration pageLoad;
    /// Time to wait for script evaluation to complete.
    Duration script;
}

class Browser
{
    /// Platform to request from the driver.
    Platform platform;
    /// Accept insecure TLS certificates.
    bool acceptInsecureCerts;
    /// Page load readiness strategy.
    PageLoadStrategy pageLoadStrategy;
    /// Support window resizing and positioning.
    bool setWindowRect;
    /// Enforce file input interactability checks.
    bool strictFileInteractability;
    /// Strategy for user prompts not handled by commands.
    UnhandledPromptBehavior unhandledPromptBehavior;
    /// Session timeout configuration.
    Timeouts timeouts;

    string name() const
        => "";

    bool generic() const
        => name.length == 0;

    bool isInstalled()
        => resolveExecutable(false) != null;

    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        if (name != null)
            ret["browserName"] = JSONValue(name);
        if (platform != Platform.Any)
            ret["platformName"] = JSONValue(cast(string)platform);
        if (acceptInsecureCerts)
            ret["acceptInsecureCerts"] = JSONValue(true);
        if (pageLoadStrategy != PageLoadStrategy.init)
            ret["pageLoadStrategy"] = JSONValue(cast(string)pageLoadStrategy);
        if (setWindowRect)
            ret["setWindowRect"] = JSONValue(true);
        if (strictFileInteractability)
            ret["strictFileInteractability"] = JSONValue(true);
        if (unhandledPromptBehavior != UnhandledPromptBehavior.init)
            ret["unhandledPromptBehavior"] = JSONValue(cast(string)unhandledPromptBehavior);

        JSONValue timeoutsObj = JSONValue.emptyObject;
        if (timeouts.implicit != Duration.init)
            timeoutsObj["implicit"] = JSONValue(cast(int)timeouts.implicit.total!"msecs");
        if (timeouts.pageLoad != Duration.init)
            timeoutsObj["pageLoad"] = JSONValue(cast(int)timeouts.pageLoad.total!"msecs");
        if (timeouts.script != Duration.init)
            timeoutsObj["script"] = JSONValue(cast(int)timeouts.script.total!"msecs");
        if (timeoutsObj.object.length > 0)
            ret["timeouts"] = timeoutsObj;

        return ret;
    }

    static Browser fromJSONValue(JSONValue json)
    {
        import selenium.browser.chrome : Chrome;
        import selenium.browser.edge : Edge;
        import selenium.browser.firefox : Firefox;
        import selenium.browser.safari : Safari;

        bool hasBrowserName(string name)
        {
            return "browserName" in json
                && json["browserName"].type == JSONType.string
                && json["browserName"].str == name;
        }

        Browser ret;
        if ("goog:chromeOptions" in json)
            ret = new Chrome();
        else if ("ms:edgeOptions" in json)
            ret = new Edge();
        else if ("moz:firefoxOptions" in json)
            ret = new Firefox();
        else if ("safari:automaticInspection" in json
            || "safari:automaticProfiling" in json
            || hasBrowserName("safari")
            || hasBrowserName("Safari Technology Preview"))
            ret = new Safari();
        else
            ret = new Browser();

        ret.parseFrom(json);
        return ret;
    }

package(selenium):
    string resolveExecutable(bool throwOnNotFound = true)
    {
        string findExecutable(string candidate)
        {
            Tuple!(int, "status", string, "output") result =
                std.process.execute(["which", candidate]);
            if (result.status == 0)
                return result.output.strip;
            return null;
        }

        immutable string[string] byName = [
            "chrome": "chromedriver",
            "firefox": "geckodriver",
            "MicrosoftEdge": "msedgedriver",
            "safari": "safaridriver",
        ];

        if (this is null)
            throw new WebDriverConnectionError("Browser instance must not be null for Web Driver executable.");

        if (!generic && name in byName)
        {
            string ret = findExecutable(byName[name]);
            if (ret != null)
                return ret;
        }

        if (generic && name !in byName)
        {
            foreach (string candidate; [
                "chromedriver",
                "geckodriver",
                "msedgedriver",
                "safaridriver",
            ])
            {
                string ret = findExecutable(candidate);
                if (ret != null)
                    return ret;
            }
        }

        if (throwOnNotFound)
            throw new WebDriverConnectionError("No WebDriver executable found on PATH.");
        return null;
    }

protected:
    void parseFrom(JSONValue json)
    {
        import selenium.browser.chrome : Chrome;
        import selenium.browser.firefox : Firefox;

        if (json.type != JSONType.object)
            throw new InvalidArgumentError("Browser capabilities must be a JSON object.");

        if ("platformName" in json && json["platformName"].type == JSONType.string)
            platform = cast(Platform)json["platformName"].str;

        if ("acceptInsecureCerts" in json && json["acceptInsecureCerts"].type == JSONType.true_)
            acceptInsecureCerts = true;
        else if ("acceptInsecureCerts" in json && json["acceptInsecureCerts"].type == JSONType.false_)
            acceptInsecureCerts = false;

        if ("pageLoadStrategy" in json && json["pageLoadStrategy"].type == JSONType.string)
            pageLoadStrategy = cast(PageLoadStrategy)json["pageLoadStrategy"].str;

        if ("setWindowRect" in json && json["setWindowRect"].type == JSONType.true_)
            setWindowRect = true;
        else if ("setWindowRect" in json && json["setWindowRect"].type == JSONType.false_)
            setWindowRect = false;

        if ("strictFileInteractability" in json && json["strictFileInteractability"].type == JSONType.true_)
            strictFileInteractability = true;
        else if ("strictFileInteractability" in json && json["strictFileInteractability"].type == JSONType.false_)
            strictFileInteractability = false;

        if ("unhandledPromptBehavior" in json && json["unhandledPromptBehavior"].type == JSONType.string)
            unhandledPromptBehavior = cast(UnhandledPromptBehavior)json["unhandledPromptBehavior"].str;

        if ("timeouts" in json)
        {
            JSONValue timeoutsObj = json["timeouts"];
            if (timeoutsObj.type == JSONType.object)
            {
                if ("implicit" in timeoutsObj && 
                    timeoutsObj["implicit"].type == JSONType.integer)
                    timeouts.implicit = dur!"msecs"(timeoutsObj["implicit"].integer);

                if ("pageLoad" in timeoutsObj && 
                    timeoutsObj["pageLoad"].type == JSONType.integer)
                    timeouts.pageLoad = dur!"msecs"(timeoutsObj["pageLoad"].integer);

                if ("script" in timeoutsObj && 
                    timeoutsObj["script"].type == JSONType.integer)
                    timeouts.script = dur!"msecs"(timeoutsObj["script"].integer);
            }
        }
    }
}
