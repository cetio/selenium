module tests.driver.frame;

import selenium.bridge : Bridge;
import selenium.element : By;

import std.json : JSONValue;

// ========== Offline tests ==========

unittest
{
    JSONValue json = By.css("div.test").toJSON();
    assert(json["using"].str == "css selector");
    assert(json["value"].str == "div.test");
}

unittest
{
    JSONValue json = By.xpath("//div[@class='test']").toJSON();
    assert(json["using"].str == "xpath");
    assert(json["value"].str == "//div[@class='test']");
}

unittest
{
    JSONValue json = By.tagName("span").toJSON();
    assert(json["using"].str == "tag name");
    assert(json["value"].str == "span");
}

unittest
{
    JSONValue json = By.linkText("Click me").toJSON();
    assert(json["using"].str == "link text");
    assert(json["value"].str == "Click me");
}

unittest
{
    JSONValue json = By.partialLinkText("Click").toJSON();
    assert(json["using"].str == "partial link text");
    assert(json["value"].str == "Click");
}

unittest
{
    JSONValue wrapper = JSONValue.emptyObject;
    wrapper["value"] = JSONValue.emptyObject;
    wrapper["value"]["element-6066-11e4-a52e-4f735466cecf"] = JSONValue("wrapped-id");
    assert(Bridge.parseElementId(wrapper) == "wrapped-id");
}

unittest
{
    JSONValue json = JSONValue.emptyObject;
    assert(Bridge.parseElementId(json) is null);
    assert(Bridge.parseElementIds(json).length == 0);
}

unittest
{
    JSONValue json = JSONValue.emptyObject;
    json["ELEMENT"] = JSONValue("legacy-id");
    json["element-6066-11e4-a52e-4f735466cecf"] = JSONValue("w3c-id");
    assert(Bridge.parseElementId(json) == "w3c-id");
}

version(integration)
{
    import selenium.driver : Driver;
    import selenium.element : Element;
    import tests.common;

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        string inner = dataUri("<html><body><p id='inner'>inside</p></body></html>");
        string html = "<html><body>"
            ~ "<p id='top'>top</p>"
            ~ "<iframe id='frame1' src='" ~ inner ~ "'></iframe>"
            ~ "</body></html>";

        driver.go(dataUri(html));
        driver.frame.switchTo(0);
        Element found = driver.find(By.css("#inner"));
        assert(found.text() == "inside");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        string iframeSrc = dataUri("<html><body><p id='nested'>nested</p></body></html>");
        string html = "<html><body><iframe id='frame1' src='" ~ iframeSrc ~ "'></iframe></body></html>";

        driver.go(dataUri(html));
        Element iframe = driver.find(By.css("iframe"));
        driver.frame.switchTo(iframe);
        Element nested = driver.find(By.css("#nested"));
        assert(nested.text() == "nested");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        string iframeSrc = dataUri("<html><body><p id='child'>child</p></body></html>");
        string html = "<html><body><p id='parent'>parent</p><iframe src='" ~ iframeSrc ~ "'></iframe></body></html>";

        driver.go(dataUri(html));
        driver.frame.switchTo(0);
        assert(driver.find(By.css("#child")).text() == "child");
        driver.frame.switchToParent();
        assert(driver.find(By.css("#parent")).text() == "parent");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        string iframeSrc = dataUri("<html><body><p id='deep'>deep</p></body></html>");
        string html = "<html><body><p id='surface'>surface</p><iframe src='" ~ iframeSrc ~ "'></iframe></body></html>";

        driver.go(dataUri(html));
        assert(driver.find(By.css("#surface")).text() == "surface");
        driver.frame.switchTo(0);
        assert(driver.find(By.css("#deep")).text() == "deep");
        driver.frame.switchTo();
        assert(driver.find(By.css("#surface")).text() == "surface");
    }
}
