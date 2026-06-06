module tests.driver.window;

import selenium.browser : Browser, Platform;
import selenium.browser.chrome : Chrome;
import selenium.bridge : Bridge;
import selenium.driver : Driver;
import selenium.element : Size;

import core.time : msecs;
import std.json : JSONValue, JSONType;

// ========== Offline tests ==========

unittest
{
    JSONValue json = JSONValue.emptyObject;
    json["element-6066-11e4-a52e-4f735466cecf"] = JSONValue("abc-123");
    assert(Bridge.parseElementId(json) == "abc-123");
}

unittest
{
    JSONValue json = JSONValue.emptyObject;
    json["ELEMENT"] = JSONValue("legacy-id");
    assert(Bridge.parseElementId(json) == "legacy-id");
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
    Chrome chrome = new Chrome();
    chrome.release = "120";
    chrome.binary = "/usr/bin/chrome";
    chrome.includeSwitches = ["--headless"];
    chrome.debuggerAddress = "127.0.0.1:9222";

    JSONValue json = chrome.toJSON();
    assert(json["browserName"].str == "chrome");
    assert(json["browserVersion"].str == "120");

    JSONValue opts = json["goog:chromeOptions"];
    assert(opts["binary"].str == "/usr/bin/chrome");
    assert(opts["args"].array.length == 1);
    assert(opts["args"].array[0].str == "--headless");
    assert(opts["debuggerAddress"].str == "127.0.0.1:9222");
}

unittest
{
    Browser browser = new Browser();
    browser.platform = Platform.Linux;
    browser.acceptInsecureCerts = true;
    browser.setWindowRect = true;
    browser.timeouts.implicit = 3_000.msecs;
    browser.timeouts.pageLoad = 5_000.msecs;
    browser.timeouts.script = 10_000.msecs;

    JSONValue json = browser.toJSON();
    Browser roundTrip = Browser.fromJSONValue(json);

    assert(roundTrip.platform == Platform.Linux);
    assert(roundTrip.acceptInsecureCerts == true);
    assert(roundTrip.setWindowRect == true);
    assert(roundTrip.timeouts.implicit == 3_000.msecs);
    assert(roundTrip.timeouts.pageLoad == 5_000.msecs);
    assert(roundTrip.timeouts.script == 10_000.msecs);
}

unittest
{
    Browser browser = new Browser();
    browser.platform = Platform.Any;
    browser.acceptInsecureCerts = false;

    JSONValue json = browser.toJSON();
    assert("platformName" !in json);
    assert("acceptInsecureCerts" !in json);
}

version(integration)
{
    import tests.common;

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><title>WindowTest</title><body></body></html>"));
        assert(driver.title() == "WindowTest");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        string handle = driver.window.handle();
        assert(handle.length > 0);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        Size original = driver.window.size();
        driver.window.resize(Size(original.width - 50, original.height - 50));
        Size changed = driver.window.size();
        assert(changed.width == original.width - 50);
        assert(changed.height == original.height - 50);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        driver.window.resize(Size(400, 400));
        driver.window.maximize();
        Size maximized = driver.window.size();
        assert(maximized.width >= 400);
        assert(maximized.height >= 400);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        driver.window.minimize();
        bool hidden = driver.execute!bool("return document.hidden;");
        assert(hidden == true);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        string[] handles = driver.window.handles();
        assert(handles.length >= 1);
    }
}
