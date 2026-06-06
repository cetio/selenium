module tests.driver.script;

import selenium.driver : Driver;
import selenium.element : Element;

import std.json : JSONValue;

// ========== Offline tests ==========

unittest
{
    JSONValue args = JSONValue.emptyArray;
    args.array ~= JSONValue("first");
    args.array ~= JSONValue(2);
    args.array ~= JSONValue.emptyObject;

    JSONValue data = JSONValue.emptyObject;
    data["script"] = JSONValue("return arguments[0];");
    data["args"] = args;

    assert(data["script"].str == "return arguments[0];");
    assert(data["args"].array.length == 3);
    assert(data["args"].array[0].str == "first");
    assert(data["args"].array[1].integer == 2);
}

version(integration)
{
    import tests.common;

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri("<html><title>ScriptTest</title><body></body></html>"));
            assert(driver.execute!string("return document.title;") == "ScriptTest",
                "title script failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri("<html><body><p id='count'>3</p></body></html>"));
            assert(driver.execute!long("return document.getElementsByTagName('p').length;") == 1,
                "element count script failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            assert(driver.execute!bool("return true;") == true,
                "bool script failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri("<html><body><a id='link'>test</a></body></html>"));
            assert(driver.execute!Element("return document.getElementById('link');").tagName == "a",
                "element script failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            assert(driver.execute!string(
                "return arguments[0] + arguments[1];",
                JSONValue([JSONValue("Hello, "), JSONValue("World!")])
            ) == "Hello, World!", "args script failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri("<html><body></body></html>"));

            bool threw = false;
            try
                driver.execute("return nonExistentFunction();");
            catch (Exception)
                threw = true;
            assert(threw, "script error did not throw for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            string[] arr = driver.execute!(string[])("return ['zero', 'one', 'two'];");
            assert(arr.length == 3, "array length failed for "~driver.browser.name);
            assert(arr[0] == "zero", "array[0] failed for "~driver.browser.name);
            assert(arr[1] == "one", "array[1] failed for "~driver.browser.name);
            assert(arr[2] == "two", "array[2] failed for "~driver.browser.name);
        });
    }
}
