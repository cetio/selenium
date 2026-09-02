module tests.webdriver.driver.window;

import selenium.bridge : Bridge;
import selenium.driver : Driver;
import selenium.element : Size;

import unit_threaded;

import std.json : JSONValue;

// ========== Offline tests ==========

@Name("parseElementId W3C key")
unittest
{
    Bridge.parseElementId(
        JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("abc-123")])
    ).should == "abc-123";
}

@Name("parseElementId legacy ELEMENT key")
unittest
{
    Bridge.parseElementId(
        JSONValue(["ELEMENT": JSONValue("legacy-id")])
    ).should == "legacy-id";
}

@Name("parseElementId wrapped value")
unittest
{
    JSONValue wrapper = JSONValue.emptyObject;
    wrapper["value"] = JSONValue.emptyObject;
    wrapper["value"]["element-6066-11e4-a52e-4f735466cecf"] = JSONValue("wrapped-id");
    Bridge.parseElementId(wrapper).should == "wrapped-id";
}

@Name("parseElementIds array")
unittest
{
    JSONValue arr = JSONValue.emptyArray;
    arr.array ~= JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("e1")]);
    arr.array ~= JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("e2")]);
    string[] ids = Bridge.parseElementIds(arr);
    ids.length.should == 2;
    ids[0].should == "e1";
    ids[1].should == "e2";
}

@Name("unwrapAndParse converts std.json values")
unittest
{
    JSONValue json = JSONValue(["value": JSONValue(["one", "two"])]);
    string[] ret = Bridge.unwrapAndParse!(string[])(json);
    ret.should == ["one", "two"];
    Bridge.unwrapAndParse!long(JSONValue(["value": JSONValue(2)])).should == 2;
}

version(integration)
{
    import tests.common;

    @Name("title returns page title") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><title>WindowTest</title><body></body></html>"));
            driver.title.should == "WindowTest";
        });
    }

    @Name("handle returns window handle") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            driver.window.handle.length.shouldBeGreaterThan(0);
        });
    }

    @Name("resize changes window size") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            Size original = driver.window.size;
            driver.window.resize(Size(original.width - 50, original.height - 50));
            Size changed = driver.window.size;
            changed.width.should == original.width - 50;
            changed.height.should == original.height - 50;
        });
    }

    @Name("maximize enlarges window") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            driver.window.resize(Size(400, 400));
            driver.window.maximize();
            Size maximized = driver.window.size;
            maximized.width.shouldBeGreaterThan(399);
            maximized.height.shouldBeGreaterThan(399);
        });
    }

    @Name("minimize hides document") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            driver.window.minimize();
            driver.execute!bool("return document.hidden;").should == true;
        });
    }

    @Name("handles returns window list") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            driver.window.handles.length.shouldBeGreaterThan(0);
        });
    }
}
