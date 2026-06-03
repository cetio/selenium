module selenium.element;

import selenium.bridge : Bridge;
import selenium.driver : Driver;

import std.array : join;
import std.json : JSONValue;
import std.net.curl : HTTP;

enum Locator : string
{
    ClassName = "class name",
    CssSelector = "css selector",
    Id = "id",
    Name = "name",
    LinkText = "link text",
    PartialLinkText = "partial link text",
    TagName = "tag name",
    XPath = "xpath"
}

struct Size
{
    long width;
    long height;
}

struct Position
{
    long x;
    long y;
}

class Element
{
public:
    Driver driver;
    string id;

    this(Driver driver, string id)
    {
        this.driver = driver;
        this.id = id;
    }

    Element find(Locator strategy, string value)
    {
        driver.bridge.ensureTimeoutsSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = driver.bridge.request(HTTP.Method.post, path("/element"), body_);
        return new Element(driver, Bridge.parseElementId(resp));
    }

    Element[] findAll(Locator strategy, string value)
    {
        driver.bridge.ensureTimeoutsSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = driver.bridge.request(HTTP.Method.post, path("/elements"), body_);
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(driver, eid);
        return ret;
    }

    string text()
        => driver.bridge.request!string(HTTP.Method.get, path("/text"));

    string tagName()
        => driver.bridge.request!string(HTTP.Method.get, path("/name"));

    void click()
    {
        driver.bridge.request(HTTP.Method.post, path("/click"));
    }

    void submit()
    {
        driver.bridge.request(HTTP.Method.post, path("/submit"));
    }

    void sendKeys(string[] keys)
    {
        driver.bridge.request(HTTP.Method.post, path("/value"), ["text": keys.join()]);
    }

    void sendKeys(string keys)
    {
        sendKeys([keys]);
    }

    void clear()
    {
        driver.bridge.request(HTTP.Method.post, path("/clear"));
    }

    bool selected()
        => driver.bridge.request!bool(HTTP.Method.get, path("/selected"));

    bool enabled()
        => driver.bridge.request!bool(HTTP.Method.get, path("/enabled"));

    bool displayed()
        => driver.bridge.request!bool(HTTP.Method.get, path("/displayed"));

    string attribute(string name)
        => driver.bridge.request!string(HTTP.Method.get, path("/attribute/"~name));

    string cssValue(string property)
        => driver.bridge.request!string(HTTP.Method.get, path("/css/"~property));

    Position position()
        => driver.bridge.request!Position(HTTP.Method.get, path("/rect"));

    Position positionInView()
        => driver.bridge.request!Position(HTTP.Method.get, path("/location_in_view"));

    Size size()
        => driver.bridge.request!Size(HTTP.Method.get, path("/rect"));

    string screenshot()
        => driver.bridge.request!string(HTTP.Method.get, path("/screenshot"));

private:
    string path(string suffix)
        => "/element/"~id~suffix;
}
