module tests.driver.element;

import selenium.bridge : Bridge;
import selenium.element : By, Element, Size, Position;

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
    JSONValue json = By.xpath("//div[@id='test']").toJSON();
    assert(json["using"].str == "xpath");
    assert(json["value"].str == "//div[@id='test']");
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
    JSONValue arr = JSONValue.emptyArray;
    arr.array ~= JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("e1")]);
    arr.array ~= JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("e2")]);
    string[] ids = Bridge.parseElementIds(arr);
    assert(ids.length == 2);
    assert(ids[0] == "e1");
    assert(ids[1] == "e2");
}

unittest
{
    JSONValue mixed = JSONValue.emptyArray;
    mixed.array ~= JSONValue(["ELEMENT": JSONValue("legacy")]);
    mixed.array ~= JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("modern")]);
    string[] ids = Bridge.parseElementIds(mixed);
    assert(ids[0] == "legacy");
    assert(ids[1] == "modern");
}

unittest
{
    JSONValue json = JSONValue.emptyObject;
    assert(Bridge.parseElementId(json) is null);
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
    import tests.common;

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><button id='btn' onclick='this.textContent=\"clicked\"'>click</button></body></html>"
        ));
        driver.find(By.css("#btn")).click();
        assert(driver.find(By.css("#btn")).text() == "clicked");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='field' value='initial'></body></html>"
        ));
        driver.find(By.css("#field")).sendKeys("abc");
        assert(driver.find(By.css("#field")).attribute("value") == "abc");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='field' value='prefilled'></body></html>"
        ));
        driver.find(By.css("#field")).clear();
        assert(driver.find(By.css("#field")).attribute("value") == "");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><div id='outer'><span id='inner'>nested</span></div></body></html>"
        ));
        Element outer = driver.find(By.css("#outer"));
        Element inner = outer.find(By.css("#inner"));
        assert(inner.text() == "nested");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><p id='t' style='color:red;'>styled</p></body></html>"
        ));
        Element elem = driver.find(By.css("#t"));
        string color = elem.cssValue("color");
        assert(color.length > 0);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='stale' value='old'></body></html>"
        ));
        Element elem = driver.find(By.css("#stale"));
        driver.refresh();

        bool threw = false;
        try
        {
            elem.attribute("value");
        }
        catch (Exception)
        {
            threw = true;
        }
        assert(threw);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='checky' type='checkbox' checked><input id='unchecky' type='checkbox'></body></html>"
        ));
        assert(driver.find(By.css("#checky")).selected() == true);
        assert(driver.find(By.css("#unchecky")).selected() == false);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='dis' disabled><input id='en'></body></html>"
        ));
        assert(driver.find(By.css("#dis")).enabled() == false);
        assert(driver.find(By.css("#en")).enabled() == true);
    }
}
