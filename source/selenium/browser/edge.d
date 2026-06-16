/// Edge capabilities and the `ms:edgeOptions` vendor object.
module selenium.browser.edge;

import selenium.browser : Browser;
import selenium.exception : InvalidArgumentException;
import selenium.driver.logger;

import std.json : JSONValue, JSONType;
import std.base64 : Base64;
import std.file : read, isFile;
import std.regex : match, ctRegex;

/// A Microsoft Edge browser with its `ms:edgeOptions` capabilities.
///
/// The options object is an Edge vendor extension. Logging still uses the Chromium
/// `goog:loggingPrefs` capability rather than an Edge-specific key, since Edge is
/// Chromium based. None of these are part of W3C.
class Edge : Browser
{
    /// Wrapper struct for preferences. Edge supports both browser (local state) and user preferences.
    /// Preferences are NOT sanitized or validated, and are expected to be JSON objects.
    struct Preferences
    {
        /// Local state preferences.
        JSONValue browser;
        /// User profile preferences.
        JSONValue user;
    }

    // https://learn.microsoft.com/en-us/microsoft-edge/webdriver/capabilities-edge-options
    /// Filter for matching a specific browser version.
    string release;
    /// Browser binary. To set a custom binary, set this to the path of the binary.
    string binary;
    /// Command inclusion arguments. To exclude default arguments, see `excludeSwitches`.
    string[] includeSwitches;
    /// Command exclusion arguments.
    string[] excludeSwitches;
    /// Preferences for browser (local state) and user.
    Preferences prefs;
    /// Debugger address. Must be in the format '<hostname/ip:port>', ie: '127.0.0.1:9222'.
    string debuggerAddress;
    /// Minidump path. Only supported for Linux environments.
    /// Setting this on a non-linux compilation will have no effect.
    string minidumpPath;
    /// Detach process from driver.
    /// If true, the browser will not be closed when the driver is closed.
    bool detach;
    /// Extensions to load. May be provided as either base-64 encoded CRX content or a path to a CRX file.
    string[] extensions;
    /// Mobile emulation configuration. Must be a JSON object.
    JSONValue mobileEmulation;
    /// Windows Device Portal address. Must be in the format '<hostname/ip:port>'.
    string wdpAddress;
    /// Windows Device Portal username.
    string wdpUsername;
    /// Windows Device Portal password.
    string wdpPassword;
    /// WebView2 options. Must be a JSON object.
    JSONValue webviewOptions;
    /// Windows application user model ID for WebView2 automation.
    string windowsApp;
    /// Use WebView2 instead of Edge browser.
    bool useWebView;
    /// Remote log level preferences per log type, serialized as `goog:loggingPrefs`.
    LogLevel[string] logging;
    
    // TODO: Support for setting custom names.
    /// The `browserName` capability, "webview2" when driving WebView2.
    override string name() const
        => useWebView ? "webview2" : "MicrosoftEdge";

    /// Serializes the standard capabilities plus `ms:edgeOptions` and logging prefs.
    override JSONValue toJSON() const
    {
        JSONValue ret = super.toJSON();
        if (release != null)
            ret["browserVersion"] = JSONValue(release);

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

        foreach (ext; extensions)
        {
            if (ext.isFile)
                opts["extensions"] ~= JSONValue(cast(string)Base64.encode(cast(ubyte[])read(ext)));
            else if (ext.match(ctRegex!(`^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$`)))
                opts["extensions"] ~= JSONValue(ext);
            else
                throw new InvalidArgumentException("Extension must be a file path or a base-64 encoded CRX content.");
        }

        if (debuggerAddress != null)
            opts["debuggerAddress"] = JSONValue(debuggerAddress);

        version (linux)
        {
            if (minidumpPath != null)
                opts["minidumpPath"] = JSONValue(minidumpPath);
        }

        if (detach)
            opts["detach"] = JSONValue(true);

        if (mobileEmulation.type == JSONType.object && mobileEmulation.object.length > 0)
            opts["mobileEmulation"] = mobileEmulation;

        if (wdpAddress != null)
            opts["wdpAddress"] = JSONValue(wdpAddress);

        if (wdpUsername != null)
            opts["wdpUsername"] = JSONValue(wdpUsername);

        if (wdpPassword != null)
            opts["wdpPassword"] = JSONValue(wdpPassword);

        if (webviewOptions.type == JSONType.object && webviewOptions.object.length > 0)
            opts["webviewOptions"] = webviewOptions;

        if (windowsApp != null)
            opts["windowsApp"] = JSONValue(windowsApp);

        if (opts.object.length > 0)
            ret["ms:edgeOptions"] = opts;

        if (logging.length > 0)
        {
            JSONValue logPrefs = JSONValue.emptyObject;
            foreach (type, level; logging)
                logPrefs[type] = JSONValue(toWebDriverLevel(level));
            ret["goog:loggingPrefs"] = logPrefs;
        }

        return ret;
    }

    /// Folds the per-type logging preferences upward into the session logger.
    override void normalizeLogger(Logger logger)
    {
        foreach (type, level; logging)
            logger.levels[type] = level;
    }

protected:
    /// Populates the standard capabilities and `ms:edgeOptions` fields.
    override void parseFrom(JSONValue value)
    {
        super.parseFrom(value);

        if ("browserVersion" in value && value["browserVersion"].type == JSONType.string)
            release = value["browserVersion"].str;

        if ("goog:loggingPrefs" in value && value["goog:loggingPrefs"].type == JSONType.object)
        {
            foreach (type, level; value["goog:loggingPrefs"].object)
            {
                if (level.type == JSONType.string)
                    logging[type] = fromWebDriverLevel(level.str);
            }
        }

        if ("ms:edgeOptions" in value)
        {
            JSONValue opts = value["ms:edgeOptions"];
            if (opts.type != JSONType.object)
                return;

            if ("binary" in opts && opts["binary"].type == JSONType.string)
                binary = opts["binary"].str;

            if ("args" in opts && opts["args"].type == JSONType.array)
            {
                foreach (JSONValue arg; opts["args"].array)
                {
                    if (arg.type == JSONType.string)
                        includeSwitches ~= arg.str;
                }
            }

            if ("excludeSwitches" in opts && opts["excludeSwitches"].type == JSONType.array)
            {
                foreach (JSONValue sw; opts["excludeSwitches"].array)
                {
                    if (sw.type == JSONType.string)
                        excludeSwitches ~= sw.str;
                }
            }

            if ("localState" in opts && opts["localState"].type == JSONType.object)
                prefs.browser = opts["localState"];

            if ("prefs" in opts && opts["prefs"].type == JSONType.object)
                prefs.user = opts["prefs"];

            if ("debuggerAddress" in opts && opts["debuggerAddress"].type == JSONType.string)
                debuggerAddress = opts["debuggerAddress"].str;

            version (linux)
            {
                if ("minidumpPath" in opts && opts["minidumpPath"].type == JSONType.string)
                    minidumpPath = opts["minidumpPath"].str;
            }

            if ("detach" in opts && opts["detach"].type == JSONType.true_)
                detach = true;
            else if ("detach" in opts && opts["detach"].type == JSONType.false_)
                detach = false;

            if ("extensions" in opts && opts["extensions"].type == JSONType.array)
            {
                foreach (JSONValue ext; opts["extensions"].array)
                {
                    if (ext.type == JSONType.string)
                        extensions ~= ext.str;
                }
            }

            if ("mobileEmulation" in opts && opts["mobileEmulation"].type == JSONType.object)
                mobileEmulation = opts["mobileEmulation"];

            if ("wdpAddress" in opts && opts["wdpAddress"].type == JSONType.string)
                wdpAddress = opts["wdpAddress"].str;

            if ("wdpUsername" in opts && opts["wdpUsername"].type == JSONType.string)
                wdpUsername = opts["wdpUsername"].str;

            if ("wdpPassword" in opts && opts["wdpPassword"].type == JSONType.string)
                wdpPassword = opts["wdpPassword"].str;

            if ("webviewOptions" in opts && opts["webviewOptions"].type == JSONType.object)
                webviewOptions = opts["webviewOptions"];

            if ("windowsApp" in opts && opts["windowsApp"].type == JSONType.string)
                windowsApp = opts["windowsApp"].str;
        }
    }
}
