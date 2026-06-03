module selenium.browser;

import std.json : JSONValue;

import core.time : Duration;

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
public:
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

    JSONValue toJSONValue() const
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
}
