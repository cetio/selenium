module selenium.element;

import selenium.bridge : Bridge;
import selenium.driver : Driver;

import std.array : join;
import std.json : JSONValue;
import std.net.curl : HTTP;

struct By
{
    string using;
    string value;

    static By css(string value)
        => By("css selector", value);

    static By tagName(string value)
        => By("tag name", value);

    static By linkText(string value)
        => By("link text", value);

    static By partialLinkText(string value)
        => By("partial link text", value);

    static By xpath(string value)
        => By("xpath", value);

    JSONValue toJSON()
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["using"] = using;
        ret["value"] = value;
        return ret;
    }
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
    Driver driver;
    string id;

    this(Driver driver, string id)
    {
        this.driver = driver;
        this.id = id;
    }

    Element find(By by)
    {
        driver.bridge.ensureTimeoutsSynced(driver.id, driver.browser);

        JSONValue resp = driver.bridge.request(driver.id, HTTP.Method.post, path("/element"), by.toJSON());
        return new Element(driver, Bridge.parseElementId(resp));
    }

    Element[] findAll(By by)
    {
        driver.bridge.ensureTimeoutsSynced(driver.id, driver.browser);

        JSONValue resp = driver.bridge.request(driver.id, HTTP.Method.post, path("/elements"), by.toJSON());
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(driver, eid);
        return ret;
    }

    string text()
        => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/text"));

    string tagName()
        => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/name"));

    void click()
    {
        driver.bridge.request(driver.id, HTTP.Method.post, path("/click"));
    }

    void sendKeys(string[] keys)
    {
        driver.bridge.request(driver.id, HTTP.Method.post, path("/value"), ["text": keys.join()]);
    }

    void sendKeys(string keys)
    {
        sendKeys([keys]);
    }

    void clear()
    {
        driver.bridge.request(driver.id, HTTP.Method.post, path("/clear"));
    }

    bool selected()
        => driver.bridge.request!bool(driver.id, HTTP.Method.get, path("/selected"));

    bool enabled()
        => driver.bridge.request!bool(driver.id, HTTP.Method.get, path("/enabled"));

    string attribute(string name)
        => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/attribute/"~name));

    string cssValue(string property)
        => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/css/"~property));

    Position position()
        => driver.bridge.request!Position(driver.id, HTTP.Method.get, path("/rect"));

    Size size()
        => driver.bridge.request!Size(driver.id, HTTP.Method.get, path("/rect"));

    string screenshot()
        => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/screenshot"));

private:
    string path(string suffix)
        => "/element/"~id~suffix;
}
