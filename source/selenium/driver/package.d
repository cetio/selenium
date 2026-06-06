module selenium.driver;

import selenium.bridge : Bridge;
import selenium.browser : Browser;
import selenium.element : By, Element, Size;
import selenium.error : WebDriverConnectionError;

import std.json : JSONValue;
import std.net.curl : HTTP;

class Driver
{
    Bridge bridge;
    Browser browser;
    string id;

    static Driver start(
        Bridge bridge, 
        Browser alwaysMatch, 
        Browser[] firstMatch
    )
    {
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
        ret.id = bridge.createSession(payload);
        ret.browser = bridge.sessions[ret.id];
        return ret;
    }

    static Driver start(Browser alwaysMatch, Browser[] firstMatch = null)
        => start(Bridge.start(null), alwaysMatch, firstMatch);

    static Driver start()
        => start(new Browser());

    void stop()
    {
        if (bridge !is null)
            bridge.closeSession(id);
    }

    string url() => bridge.request!string(id, HTTP.Method.get, "/url");
    string title() => bridge.request!string(id, HTTP.Method.get, "/title");
    string source() => bridge.request!string(id, HTTP.Method.get, "/source");
    string screenshot() => bridge.request!string(id, HTTP.Method.get, "/screenshot");

    void go(string url)
    {
        bridge.ensureTimeoutsSynced(id, browser);
        bridge.request(id, HTTP.Method.post, "/url", ["url": url]);
    }
    void back() => bridge.request!void(id, HTTP.Method.post, "/back");
    void forward() => bridge.request!void(id, HTTP.Method.post, "/forward");
    void refresh() => bridge.request!void(id, HTTP.Method.post, "/refresh");

    Element activeElement() 
        => new Element(this, Bridge.parseElementId(bridge.request(id, HTTP.Method.get, "/element/active")));

    Element find(By by)
    {
        bridge.ensureTimeoutsSynced(id, browser);

        JSONValue resp = bridge.request(id, HTTP.Method.post, "/element", by.toJSON());
        return new Element(this, Bridge.parseElementId(resp));
    }

    Element[] findAll(By by)
    {
        bridge.ensureTimeoutsSynced(id, browser);

        JSONValue resp = bridge.request(id, HTTP.Method.post, "/elements", by.toJSON());
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(this, eid);
        return ret;
    }

    T execute(T = string)(string script, JSONValue args = JSONValue.emptyArray)
    {
        bridge.ensureTimeoutsSynced(id, browser);
        return bridge.request!T(id, HTTP.Method.post, "/execute/sync", [
            "script": JSONValue(script),
            "args": args,
        ]);
    }

    // TODO: executeAsync
    // TODO: auto retry on stale element references

    // Templates are used for grouping. Adding an alias is required to allow for functionality like `driver.window.handles`.
    // This is NOT used for some capabilities (ie: Cookies) which may be desirable to decouple from the driver itself.

    template Window()
    {
        string handle() => bridge.request!string(id, HTTP.Method.get, "/window");
        string[] handles() => bridge.request!(string[])(id, HTTP.Method.get, "/window/handles");
        Size size() => bridge.request!Size(id, HTTP.Method.get, "/window/rect");
        void close() => bridge.request!void(id, HTTP.Method.del, "/window");
        void maximize() => bridge.request!void(id, HTTP.Method.post, "/window/maximize");
        void fullscreen() => bridge.request!void(id, HTTP.Method.post, "/window/fullscreen");
        void minimize() => bridge.request!void(id, HTTP.Method.post, "/window/minimize");
        void resize(Size value) => bridge.request!void(id, HTTP.Method.post, "/window/rect", value);
    }
    alias window = Window!();

    template Frame()
    {
        void switchTo() => bridge.request!void(this.id, HTTP.Method.post, "/frame", ["id": JSONValue(null)]);
        void switchTo(long id) => bridge.request!void(this.id, HTTP.Method.post, "/frame", ["id": id]);
        void switchTo(Element element)
        {
            JSONValue elementRef = JSONValue.emptyObject;
            elementRef[Bridge.W3C_KEY] = JSONValue(element.id);
            bridge.request!void(this.id, HTTP.Method.post, "/frame", ["id": elementRef]);
        }
        void switchToParent() => bridge.request!void(this.id, HTTP.Method.post, "/frame/parent");
    }
    alias frame = Frame!();
}
