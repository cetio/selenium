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
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><title>ScriptTest</title><body></body></html>"));
        assert(driver.execute!string("return document.title;") == "ScriptTest");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body><p id='count'>3</p></body></html>"));
        assert(driver.execute!long("return document.getElementsByTagName('p').length;") == 1);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        assert(driver.execute!bool("return true;") == true);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body><a id='link'>test</a></body></html>"));
        assert(driver.execute!Element("return document.getElementById('link');").tagName == "a");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        assert(driver.execute!string(
            "return arguments[0] + arguments[1];",
            JSONValue([JSONValue("Hello, "), JSONValue("World!")])
        ) == "Hello, World!");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));

        bool threw = false;
        try
            driver.execute("return nonExistentFunction();");
        catch (Exception)
            threw = true;
        assert(threw);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><body></body></html>"));
        string[] arr = driver.execute!(string[])("return ['zero', 'one', 'two'];");
        assert(arr.length == 3);
        assert(arr[0] == "zero");
        assert(arr[1] == "one");
        assert(arr[2] == "two");
    }
}
