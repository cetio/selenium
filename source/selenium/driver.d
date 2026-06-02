module selenium.driver;

import selenium.browser : Browser;
import selenium.bridge : Bridge;
import selenium.element : Element, Size;
import selenium.error : WebDriverConnectionError;
import selenium.options : Options;
public import selenium.element : Locator;

import std.json : JSONType, JSONValue;
import std.net.curl : HTTP;
import std.stdio : File, stderr, stdout;
import core.time : Duration;

class Driver
{
public:
    Bridge bridge;
    Options options;

    ref Duration implicitWait() => bridge.implicitWait;

    static Driver start(Options options = Options())
    {
        Driver ret = new Driver();
        ret.options = options;
        ret.bridge = Bridge.start(options);
        return ret;
    }

    static Driver start(Browser browsers...)
        => start(Options(browsers));

    void quit()
    {
        if (bridge is null)
            return;

        try
            bridge.disconnect();
        catch (Exception) { }
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
        bridge.ensureImplicitWaitSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = bridge.request(HTTP.Method.post, "/element", body_);
        return new Element(bridge, Bridge.parseElementId(resp));
    }

    Element[] findAll(Locator strategy, string value)
    {
        bridge.ensureImplicitWaitSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = bridge.request(HTTP.Method.post, "/elements", body_);
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(bridge, eid);
        return ret;
    }

    Element activeElement()
        => new Element(bridge, Bridge.parseElementId(bridge.request(HTTP.Method.get, "/element/active")));

    T execute(T = string)(string script, JSONValue args = JSONValue.emptyArray)
    {
        return bridge.request!T(HTTP.Method.post, "/execute/sync", [
            "script": JSONValue(script),
            "args": args,
        ]);
    }

    string screenshot()
        => bridge.request!string(HTTP.Method.get, "/screenshot");

    // void wait(Duration timeout, Duration interval, bool delegate() poll)
    // {
        
    // }

private:
    this() { }

}
