module tests.driver.script;

import selenium.bridge : Bridge;
import selenium.browser : Browser;
import selenium.browser.chrome : Chrome;
import selenium.driver : Driver;

import std.json : JSONValue;

// ========== Offline tests ==========

unittest
{
    JSONValue response = JSONValue.emptyObject;
    response["element-6066-11e4-a52e-4f735466cecf"] = JSONValue("elem-id");
    assert(Bridge.parseElementId(response) == "elem-id");
}

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
    import selenium.element : Element;
    import tests.common;

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><title>ScriptTest</title><body></body></html>"));
        string title = driver.execute!string("return document.title;");
        assert(title == "ScriptTest");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body><p id='count'>3</p></body></html>"));
        long count = driver.execute!long("return document.getElementsByTagName('p').length;");
        assert(count == 1);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        bool result = driver.execute!bool("return true;");
        assert(result == true);
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body><a id='link'>test</a></body></html>"));
        Element elem = driver.execute!Element("return document.getElementById('link');");
        assert(elem.tagName() == "a");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        string result = driver.execute!string(
            "return arguments[0] + arguments[1];",
            JSONValue([JSONValue("Hello, "), JSONValue("World!")])
        );
        assert(result == "Hello, World!");
    }

    unittest
    {
        Driver driver = startTestDriver();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));

        bool threw = false;
        try
        {
            driver.execute("return nonExistentFunction();");
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

        driver.go(dataUri("<html><body></body></html>"));
        string[] arr = driver.execute!(string[])("return ['zero', 'one', 'two'];");
        assert(arr.length == 3);
        assert(arr[0] == "zero");
        assert(arr[1] == "one");
        assert(arr[2] == "two");
    }
}
