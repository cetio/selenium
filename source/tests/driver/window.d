module tests.driver.window;

import selenium.bridge : Bridge;
import selenium.driver : Driver;
import selenium.element : Size;

import std.json : JSONValue;

// ========== Offline tests ==========

unittest
{
    assert(Bridge.parseElementId(
        JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("abc-123")])
    ) == "abc-123");
}

unittest
{
    assert(Bridge.parseElementId(
        JSONValue(["ELEMENT": JSONValue("legacy-id")])
    ) == "legacy-id");
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

version(integration)
{
    import tests.common;

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><title>WindowTest</title><body></body></html>"));
        assert(driver.title == "WindowTest");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        assert(driver.window.handle.length > 0);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        Size original = driver.window.size;
        driver.window.resize(Size(original.width - 50, original.height - 50));
        Size changed = driver.window.size;
        assert(changed.width == original.width - 50);
        assert(changed.height == original.height - 50);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        driver.window.resize(Size(400, 400));
        driver.window.maximize();
        Size maximized = driver.window.size;
        assert(maximized.width >= 400);
        assert(maximized.height >= 400);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        driver.window.minimize();
        assert(driver.execute!bool("return document.hidden;") == true);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        assert(driver.window.handles.length >= 1);
    }
}
