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

    static Driver start(Bridge bridge, Browser alwaysMatch, Browser[] firstMatch...)
    {
        JSONValue payload = JSONValue.emptyObject;
        JSONValue capabilities = JSONValue.emptyObject;
        capabilities["alwaysMatch"] = alwaysMatch.toJSON();

        JSONValue[] firstMatchJson;
        foreach (browser; firstMatch)
            firstMatchJson ~= browser.toJSON();
        if (firstMatchJson.length > 0)
            capabilities["firstMatch"] = JSONValue(firstMatchJson);

        payload["capabilities"] = capabilities;

        Driver ret = new Driver();
        ret.bridge = bridge;
        ret.id = bridge.createSession(payload);
        ret.browser = bridge.sessions[ret.id];
        return ret;
    }

    static Driver start(Browser alwaysMatch, Browser[] firstMatch...)
    {
        Bridge spawned = Bridge.start(null);
        return start(spawned, alwaysMatch, firstMatch);
    }

    static Driver start()
    {
        return start(new Browser());
    }

    void stop()
    {
        if (bridge !is null)
            bridge.closeSession(id);
    }

    string url()
        => bridge.request!string(id, HTTP.Method.get, "/url");

    void navigate(string url)
    {
        bridge.ensureTimeoutsSynced(id, browser);
        bridge.request(id, HTTP.Method.post, "/url", ["url": url]);
    }

    void back()
    {
        bridge.request(id, HTTP.Method.post, "/back");
    }

    void forward()
    {
        bridge.request(id, HTTP.Method.post, "/forward");
    }

    void refresh()
    {
        bridge.request(id, HTTP.Method.post, "/refresh");
    }

    string title()
        => bridge.request!string(id, HTTP.Method.get, "/title");

    string source()
        => bridge.request!string(id, HTTP.Method.get, "/source");

    @property string windowHandle()
        => bridge.request!string(id, HTTP.Method.get, "/window");

    @property void windowHandle(string handle)
    {
        bridge.request(id, HTTP.Method.post, "/window", ["handle": handle]);
    }

    string[] windowHandles()
        => bridge.request!(string[])(id, HTTP.Method.get, "/window/handles");

    void closeWindow()
    {
        bridge.request(id, HTTP.Method.del, "/window");
    }

    void maximize()
    {
        bridge.request(id, HTTP.Method.post, "/window/maximize");
    }

    @property Size windowSize()
        => bridge.request!Size(id, HTTP.Method.get, "/window/rect");

    @property void windowSize(Size value)
    {
        bridge.request(id, HTTP.Method.post, "/window/rect", value);
    }

    void frame(string id)
    {
        bridge.request(this.id, HTTP.Method.post, "/frame", ["id": id]);
    }

    void frame(long id)
    {
        bridge.request(this.id, HTTP.Method.post, "/frame", ["id": id]);
    }

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

    Element activeElement()
        => new Element(this, Bridge.parseElementId(bridge.request(id, HTTP.Method.get, "/element/active")));

    T execute(T = string)(string script, JSONValue args = JSONValue.emptyArray)
    {
        bridge.ensureTimeoutsSynced(id, browser);
        return bridge.request!T(id, HTTP.Method.post, "/execute/sync", [
            "script": JSONValue(script),
            "args": args,
        ]);
    }

    // TODO: executeAsync
    // TODO: cookies
    // TODO: auto retry on stale element references

    string screenshot()
        => bridge.request!string(id, HTTP.Method.get, "/screenshot");

private:
    this() { }
}
