/// A handle to a single WebDriver session and its navigation commands.
module selenium.driver;

import selenium.bridge : Bridge;
import selenium.browser : Browser;
import selenium.element : By, Element, Size;
import selenium.root : Root, RootState, RootType;
import selenium.driver.logger : Logger;
import std.json : JSONValue;
import std.net.curl : HTTP;

/// A handle to one WebDriver session living on a `Bridge`.
///
/// W3C and most clients treat a driver as 1:1 with a session, but that is not the
/// shape here. A `Bridge` can own several sessions at once, and each Driver is a
/// handle to exactly one of them, so multiple drivers may share a single Bridge.
///
/// Unlike `Bridge`, a Driver does not destruct automatically. `stop` ends only this
/// driver's session and deliberately leaves the Bridge alive for its other sessions.
class Driver
{
    /// The connection hosting this session.
    Bridge bridge;
    /// The browser whose capabilities were negotiated for this session.
    Browser browser;
    /// The logger aggregating client, driver, and remote logging for this session.
    Logger logger;
    /// The W3C session id.
    string id;

    /**
     * Starts a session on an existing bridge.
     *
     * Each browser's logging configuration is merged into the logger before the
     * capabilities are built, so per-browser preferences propagate upward into the
     * single session logger. The capabilities use `alwaysMatch` for the required
     * browser and `firstMatch` for acceptable alternatives.
     *
     * Params:
     *  bridge = The connection to create the session on.
     *  alwaysMatch = The required browser capabilities.
     *  firstMatch = Alternative capability sets the server may pick from.
     *  logger = The logger to attach, or null to create a default one.
     *
     * Returns:
     *  A driver bound to the new session.
     */
    static Driver start(Bridge bridge, Browser alwaysMatch, Browser[] firstMatch, Logger logger = null)
    {
        if (logger is null)
            logger = new Logger();

        alwaysMatch.normalizeLogger(logger);
        if (firstMatch != null)
        {
            foreach (browser; firstMatch)
                browser.normalizeLogger(logger);
        }

        JSONValue payload = JSONValue.emptyObject;
        JSONValue capabilities = JSONValue.emptyObject;
        capabilities["alwaysMatch"] = alwaysMatch.toJSON();
        if (firstMatch != null)
        {
            capabilities["firstMatch"] = JSONValue.emptyArray;
            foreach (browser; firstMatch)
                capabilities["firstMatch"] ~= browser.toJSON();
        }
        payload["capabilities"] = capabilities;

        Driver ret = new Driver();
        ret.bridge = bridge;
        ret.logger = logger;
        ret.id = bridge.createSession(payload);
        ret.browser = bridge.sessions[ret.id];
        ret.logger.driver = ret;
        return ret;
    }

    /**
     * Resolves a driver binary, spawns a bridge for it, and starts a session.
     *
     * Convenience entry point for the common case of owning a freshly spawned
     * driver process. Driver-process logging arguments are derived from the logger.
     *
     * Params:
     *  alwaysMatch = The required browser capabilities, also used to resolve the binary.
     *  firstMatch = Alternative capability sets the server may pick from.
     *  logger = The logger to attach, or null to create a default one.
     *
     * Returns:
     *  A driver bound to a session on a newly spawned bridge.
     */
    static Driver start(Browser alwaysMatch, Browser[] firstMatch = null, Logger logger = null)
    {
        if (logger is null)
            logger = new Logger();
        return start(Bridge.start(alwaysMatch.resolveBinary(), logger.toDriverArgs()), alwaysMatch, firstMatch, logger);
    }

    /// Starts a session with a generic browser, letting the first driver on PATH win.
    static Driver start()
        => start(new Browser());

    /// Ends this session, leaving the bridge and its other sessions intact.
    void stop()
    {
        if (bridge !is null)
            bridge.closeSession(id);
    }

    /// The current document URL.
    string url() => bridge.request!string(id, HTTP.Method.get, "/url");
    /// The current document title.
    string title() => bridge.request!string(id, HTTP.Method.get, "/title");
    /// The serialized source of the current document.
    string source() => bridge.request!string(id, HTTP.Method.get, "/source");
    /// A base64 PNG screenshot of the current viewport.
    string screenshot() => bridge.request!string(id, HTTP.Method.get, "/screenshot");

    /**
     * Navigates the session to a URL.
     *
     * Params:
     *  url = The destination URL.
     */
    void go(string url)
    {
        bridge.ensureTimeoutsSynced(id, browser);
        bridge.request(id, HTTP.Method.post, "/url", ["url": url]);
    }
    /// Navigates back one entry in history.
    void back() => bridge.request!void(id, HTTP.Method.post, "/back");
    /// Navigates forward one entry in history.
    void forward() => bridge.request!void(id, HTTP.Method.post, "/forward");
    /// Reloads the current document.
    void refresh() => bridge.request!void(id, HTTP.Method.post, "/refresh");

    /// The element that currently has focus.
    Element activeElement()
        => new Element(this, Bridge.parseElementId(bridge.request(id, HTTP.Method.get, "/element/active")));

    /// The primary document root.
    Root root()
        => new Root(this, null, RootType.Primary, RootState.Complete);

    /**
     * All searchable roots in the current browsing context.
     *
     * Requires JavaScript execution. The primary document is always first.
     * Shadow roots and iframes are discovered by traversing the DOM.
     */
    Root[] roots()
    {
        bridge.ensureTimeoutsSynced(id, browser);

        JSONValue result = execute!JSONValue(`
            var UNINITIALIZED = 1, LOADING = 2, LOADED = 4, INTERACTIVE = 8, COMPLETE = 16, OPEN = 32, CLOSED = 64;
            function stateFromDoc(doc) {
                switch (doc.readyState) {
                    case "uninitialized": return UNINITIALIZED;
                    case "loading": return LOADING;
                    case "interactive": return INTERACTIVE;
                    case "complete": return COMPLETE;
                    default: return UNINITIALIZED;
                }
            }
            var roots = [];
            roots.push({type: 0, state: stateFromDoc(document)});
            var iframes = document.querySelectorAll("iframe");
            for (var i = 0; i < iframes.length; i++) {
                var fs = UNINITIALIZED;
                try { fs = iframes[i].contentDocument ? stateFromDoc(iframes[i].contentDocument) : UNINITIALIZED; }
                catch (e) { fs = UNINITIALIZED; }
                roots.push({type: 1, state: fs, ref: iframes[i]});
            }
            function walk(node) {
                if (node.shadowRoot) {
                    var sr = node.shadowRoot;
                    var ss = (sr.mode === "open" ? OPEN : CLOSED) | stateFromDoc(sr.ownerDocument);
                    roots.push({type: 2, state: ss, ref: sr});
                    walk(sr);
                }
                if (node.children) {
                    for (var i = 0; i < node.children.length; i++) walk(node.children[i]);
                }
            }
            walk(document.documentElement);
            return roots;
        `);

        Root[] ret;
        foreach (item; result.array)
        {
            int typeInt = cast(int)item["type"].integer;
            uint stateInt = cast(uint)item["state"].integer;

            RootType rootType;
            string rootId;

            switch (typeInt)
            {
                case 0:
                    rootType = RootType.Primary;
                    break;
                case 1:
                    rootType = RootType.Embedded;
                    JSONValue refValue = item["ref"];
                    rootId = Bridge.parseElementId(refValue);
                    break;
                case 2:
                    rootType = RootType.Shadow;
                    JSONValue refValue = item["ref"];
                    rootId = Bridge.parseShadowId(refValue);
                    break;
                default:
                    continue;
            }

            ret ~= new Root(this, rootId, rootType, cast(RootState)stateInt);
        }
        return ret;
    }

    /**
     * Finds the first element matching the locator.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  A handle to the matched element.
     *
     * Throws:
     *  NoSuchElementException if no element matches.
     */
    Element find(By by)
    {
        bridge.ensureTimeoutsSynced(id, browser);

        JSONValue resp = bridge.request(id, HTTP.Method.post, "/element", by.toJSON());
        return new Element(this, Bridge.parseElementId(resp));
    }

    /**
     * Finds every element matching the locator.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  Handles to all matched elements, or an empty array if none match.
     */
    Element[] findAll(By by)
    {
        bridge.ensureTimeoutsSynced(id, browser);

        JSONValue resp = bridge.request(id, HTTP.Method.post, "/elements", by.toJSON());
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(this, eid);
        return ret;
    }

    /**
     * Runs a synchronous script in the page and returns its typed result.
     *
     * When T is Element or Element[] the returned references are wrapped into
     * handles, otherwise the result is deserialized into T.
     *
     * Params:
     *  script = The script body, which may return a value.
     *  args = The arguments exposed to the script as `arguments`.
     *
     * Returns:
     *  The script result as T.
     */
    T execute(T = string)(string script, JSONValue args = JSONValue.emptyArray)
    {
        bridge.ensureTimeoutsSynced(id, browser);
        JSONValue resp = bridge.request(id, HTTP.Method.post, "/execute/sync", [
            "script": JSONValue(script),
            "args": args,
        ]);

        static if (is(T == Element))
            return new Element(this, Bridge.parseElementId(resp));
        else static if (is(T == Element[]))
        {
            Element[] ret;
            foreach (eid; Bridge.parseElementIds(resp))
                ret ~= new Element(this, eid);
            return ret;
        }
        else
            return bridge.unwrapAndParse!T(resp);
    }

    // TODO: executeAsync
    // TODO: auto retry on stale element references

    // Templates are used for grouping. Adding an alias is required to allow for functionality like `driver.window.handles`.
    // This is NOT used for some capabilities (ie: Cookies) which may be desirable to decouple from the driver itself.

    /// Window and tab commands, accessed through the `window` alias.
    template Window()
    {
        /// The handle of the current window.
        string handle() => bridge.request!string(id, HTTP.Method.get, "/window");
        /// Handles of all open windows.
        string[] handles() => bridge.request!(string[])(id, HTTP.Method.get, "/window/handles");
        /// The size of the current window.
        Size size() => bridge.request!Size(id, HTTP.Method.get, "/window/rect");
        /// Closes the current window.
        void close() => bridge.request!void(id, HTTP.Method.del, "/window");
        /// Maximizes the current window.
        void maximize() => bridge.request!void(id, HTTP.Method.post, "/window/maximize");
        /// Makes the current window fullscreen.
        void fullscreen() => bridge.request!void(id, HTTP.Method.post, "/window/fullscreen");
        /// Minimizes the current window.
        void minimize() => bridge.request!void(id, HTTP.Method.post, "/window/minimize");
        /// Resizes the current window.
        void resize(Size value) => bridge.request!void(id, HTTP.Method.post, "/window/rect", value);
        /// Switches focus to the window with the given handle.
        void switchTo(string handle) => bridge.request!void(id, HTTP.Method.post, "/window", ["handle": handle]);
        /// Opens a new window or tab and returns its handle.
        string open(string type = "tab")
            => bridge.request(id, HTTP.Method.post, "/window/new", ["type": type])["value"]["handle"].str;
    }
    /// Window command group, e.g. `driver.window.handles`.
    alias window = Window!();

    /// Frame switching commands, accessed through the `frame` alias.
    template Frame()
    {
        /// Switches focus to the top-level browsing context.
        void switchTo() => bridge.request!void(this.id, HTTP.Method.post, "/frame", ["id": JSONValue(null)]);
        /// Switches focus to the frame at the given index.
        void switchTo(long id) => bridge.request!void(this.id, HTTP.Method.post, "/frame", ["id": id]);
        /// Switches focus to the frame identified by the given element.
        void switchTo(Element element)
            => bridge.request!void(this.id, HTTP.Method.post, "/frame", ["id": element.toJSON()]);
        /// Switches focus to the parent of the current frame.
        void switchToParent() => bridge.request!void(this.id, HTTP.Method.post, "/frame/parent");
    }
    /// Frame command group, e.g. `driver.frame.switchTo(0)`.
    alias frame = Frame!();
}
