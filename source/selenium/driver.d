module selenium.driver;

import selenium.bridge : Bridge;
import selenium.element : Element, Size;
import selenium.error : WebDriverConnectionError;
import selenium.target : Target;
public import selenium.element : Locator;

import std.json : JSONValue;
import std.net.curl : HTTP;

class Driver
{
    Bridge bridge;
    string sessionId;

    static Driver start(Target target = new Target())
    {
        Driver ret = new Driver();
        ret.bridge = new Bridge(target);
        ret.sessionId = ret.bridge.start();
        return ret;
    }

    void quit()
    {
        if (bridge !is null)
            bridge.stop();
    }

    void stop()
    {
        if (bridge !is null)
            bridge.stop();
    }

    string url()
        => bridge.request!string(HTTP.Method.get, "/url");

    void navigate(string url)
    {
        bridge.ensureTimeoutsSynced();
        bridge.request(HTTP.Method.post, "/url", ["url": url]);
    }

    void back()
    {
        bridge.request(HTTP.Method.post, "/back");
    }

    void forward()
    {
        bridge.request(HTTP.Method.post, "/forward");
    }

    void refresh()
    {
        bridge.request(HTTP.Method.post, "/refresh");
    }

    string title()
        => bridge.request!string(HTTP.Method.get, "/title");

    string source()
        => bridge.request!string(HTTP.Method.get, "/source");

    string windowHandle()
        => bridge.request!string(HTTP.Method.get, "/window");

    void window(string handle)
    {
        bridge.request(HTTP.Method.post, "/window", ["handle": handle]);
    }

    string[] windowHandles()
        => bridge.handles();

    void closeWindow()
    {
        bridge.request(HTTP.Method.del, "/window");
    }

    void maximize()
    {
        bridge.request(HTTP.Method.post, "/window/maximize");
    }

    Size windowSize()
        => bridge.request!Size(HTTP.Method.get, "/window/rect");

    void windowSize(Size value)
    {
        bridge.request(HTTP.Method.post, "/window/rect", value);
    }

    void frame(string id)
    {
        bridge.request(HTTP.Method.post, "/frame", ["id": id]);
    }

    void frame(long id)
    {
        bridge.request(HTTP.Method.post, "/frame", ["id": id]);
    }

    Element find(Locator strategy, string value)
    {
        bridge.ensureTimeoutsSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = bridge.request(HTTP.Method.post, "/element", body_);
        return new Element(this, Bridge.parseElementId(resp));
    }

    Element[] findAll(Locator strategy, string value)
    {
        bridge.ensureTimeoutsSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = bridge.request(HTTP.Method.post, "/elements", body_);
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(this, eid);
        return ret;
    }

    Element activeElement()
        => new Element(this, Bridge.parseElementId(bridge.request(HTTP.Method.get, "/element/active")));

    T execute(T = string)(string script, JSONValue args = JSONValue.emptyArray)
    {
        bridge.ensureTimeoutsSynced();
        return bridge.request!T(HTTP.Method.post, "/execute/sync", [
            "script": JSONValue(script),
            "args": args,
        ]);
    }

    string screenshot()
        => bridge.request!string(HTTP.Method.get, "/screenshot");

private:
    this() { }

}
