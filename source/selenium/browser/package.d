/// The generic browser capabilities base and its capability serialization.
module selenium.browser;

import selenium.exception : InvalidArgumentException, WebDriverConnectionException;
import selenium.driver.logger : Logger;

import std.json : JSONValue, JSONType;
import std.typecons : Tuple;
import std.string : strip;
static import std.process;
import core.time : Duration, dur;

/// How far a navigation must progress before it is considered complete.
enum PageLoadStrategy : string
{
    /// Wait for the full document load event.
    Normal = "normal",
    /// Wait only until the DOM is interactive.
    Eager = "eager",
    /// Return as soon as navigation begins.
    None = "none"
}

/// How the driver should treat user prompts that no command handles.
enum UnhandledPromptBehavior : string
{
    /// Dismiss the prompt silently.
    Dismiss = "dismiss",
    /// Accept the prompt silently.
    Accept = "accept",
    /// Dismiss the prompt and raise an error.
    DismissAndNotify = "dismiss and notify",
    /// Accept the prompt and raise an error.
    AcceptAndNotify = "accept and notify",
    /// Leave the prompt open.
    Ignore = "ignore"
}

/// The requested host platform, mapped to the `platformName` capability.
enum Platform : string
{
    /// No platform constraint.
    Any = "",
    /// Windows.
    Windows = "Windows",
    /// Linux.
    Linux = "Linux",
    /// macOS.
    Mac = "Mac",
    /// Android.
    Android = "Android"
}

/// Per-session wait limits for commands that may block.
struct Timeouts
{
    /// Time to wait for an element to exist when locating.
    Duration implicit;
    /// Time to wait for page navigation to complete.
    Duration pageLoad;
    /// Time to wait for script evaluation to complete.
    Duration script;
}

/// The generic browser capabilities common to every browser.
///
/// This base mirrors the W3C standard capabilities and serializes 1:1 to them.
/// The concrete subclasses add vendor capability objects that are not part of W3C.
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

    /// The `browserName` capability, empty for a generic browser.
    string name() const
        => "";

    /// Whether this is the generic base rather than a named browser.
    bool generic() const
        => name.length == 0;

    /// Extra service arguments to pass when launching the WebDriver process.
    ///
    /// A hook for subclasses to wire process-level features into the bridge.
    /// The base returns none.
    string[] driverArgs() const
        => null;

    /**
     * Folds this browser's logging preferences upward into the session logger.
     *
     * The base is a no-op. Subclasses with logging capabilities override it so
     * their `levels` accumulate on the shared `Logger`.
     *
     * Params:
     *  logger = The session logger to normalize into.
     */
    void normalizeLogger(Logger logger) { }

    /// Whether a matching WebDriver binary can be found on PATH.
    bool isInstalled()
        => resolveBinary(false) != null;

    /**
     * Resolves the WebDriver binary for this browser on PATH.
     *
     * A named browser resolves its specific driver, while a generic browser scans
     * the known drivers and returns the first one present.
     *
     * Params:
     *  throwOnNotFound = Whether to throw when no binary is found.
     *
     * Returns:
     *  The resolved binary path, or null when none is found and throwing is disabled.
     *
     * Throws:
     *  WebDriverConnectionException if no binary is found and throwOnNotFound is true.
     */
    string resolveBinary(bool throwOnNotFound = true)
    {
        string findBinary(string candidate)
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
            throw new WebDriverConnectionException("Browser instance must not be null for Web Driver binary.");

        if (!generic && name in byName)
        {
            string ret = findBinary(byName[name]);
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
                string ret = findBinary(candidate);
                if (ret != null)
                    return ret;
            }
        }

        if (throwOnNotFound)
            throw new WebDriverConnectionException("No WebDriver binary found on PATH for '"~name~"'.");
        return null;
    }

    /// Serializes the standard W3C capabilities, omitting fields left at default.
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

    /**
     * Builds the most specific browser subclass from a capabilities object.
     *
     * Chrome and Edge are detected by the presence of their vendor options keys
     * rather than `browserName`, so a browser configured with only standard
     * capabilities or logging prefs will round-trip as the generic base instead of
     * the concrete subclass.
     *
     * Params:
     *  json = The capabilities object to parse.
     *
     * Returns:
     *  A browser instance of the detected concrete type.
     */
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

protected:
    /// Populates the standard W3C capability fields from a capabilities object.
    void parseFrom(JSONValue json)
    {
        import selenium.browser.chrome : Chrome;
        import selenium.browser.firefox : Firefox;

        if (json.type != JSONType.object)
            throw new InvalidArgumentException("Browser capabilities must be a JSON object.");

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
