module selenium.element;

import selenium.bridge : Bridge;
import selenium.types : Locator, Position, Size;

import std.json : JSONValue;
import std.net.curl : HTTP;

class Element
{
public:
    Bridge bridge;
    string id;

    this(Bridge bridge, string id)
    {
        this.bridge = bridge;
        this.id = id;
    }

    Element find(Locator strategy, string value)
    {
        bridge.ensureImplicitWaitSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = bridge.request(HTTP.Method.post, path("/element"), body_);
        return new Element(bridge, Bridge.parseElementId(resp));
    }

    Element[] findAll(Locator strategy, string value)
    {
        bridge.ensureImplicitWaitSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = bridge.request(HTTP.Method.post, path("/elements"), body_);
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(bridge, eid);
        return ret;
    }

    string text()
        => bridge.request!string(HTTP.Method.get, path("/text"));

    string tagName()
        => bridge.request!string(HTTP.Method.get, path("/name"));

    void click()
    {
        bridge.request(HTTP.Method.post, path("/click"));
    }

    void submit()
    {
        bridge.request(HTTP.Method.post, path("/submit"));
    }

    void sendKeys(string[] keys)
    {
        bridge.request(HTTP.Method.post, path("/value"), ["value": keys]);
    }

    void sendKeys(string keys)
    {
        sendKeys([keys]);
    }

    void clear()
    {
        bridge.request(HTTP.Method.post, path("/clear"));
    }

    bool selected()
        => bridge.request!bool(HTTP.Method.get, path("/selected"));

    bool enabled()
        => bridge.request!bool(HTTP.Method.get, path("/enabled"));

    bool displayed()
        => bridge.request!bool(HTTP.Method.get, path("/displayed"));

    string attribute(string name)
        => bridge.request!string(HTTP.Method.get, path("/attribute/"~name));

    string cssValue(string property)
        => bridge.request!string(HTTP.Method.get, path("/css/"~property));

    Position position()
        => bridge.request!Position(HTTP.Method.get, path("/rect"));

    Position positionInView()
        => bridge.request!Position(HTTP.Method.get, path("/location_in_view"));

    Size size()
        => bridge.request!Size(HTTP.Method.get, path("/rect"));

    string screenshot()
        => bridge.request!string(HTTP.Method.get, path("/screenshot"));

private:
    string path(string suffix)
        => "/element/"~id~suffix;
}
