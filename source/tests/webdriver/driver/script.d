module tests.webdriver.driver.script;

import selenium.driver : Driver;
import selenium.element : Element;
import selenium.exception : JavaScriptException;

import unit_threaded;

import std.json : JSONValue;

version(integration)
{
    import tests.common;

    @Name("execute returns document title") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><title>ScriptTest</title><body></body></html>"));
            driver.execute!string("return document.title;").should == "ScriptTest";
        });
    }

    @Name("execute returns element count") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body><p id='count'>3</p></body></html>"));
            driver.execute!long("return document.getElementsByTagName('p').length;").should == 1;
        });
    }

    @Name("execute returns boolean") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            driver.execute!bool("return true;").should == true;
        });
    }

    @Name("execute returns element") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body><a id='link'>test</a></body></html>"));
            driver.execute!Element("return document.getElementById('link');").tagName.should == "a";
        });
    }

    @Name("execute passes arguments") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            driver.execute!string(
                "return arguments[0] + arguments[1];",
                JSONValue([JSONValue("Hello, "), JSONValue("World!")])
            ).should == "Hello, World!";
        });
    }

    @Name("execute throws on script error") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            driver.execute("return nonExistentFunction();").shouldThrow!JavaScriptException;
        });
    }

    @Name("execute returns string array") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body></body></html>"));
            string[] arr = driver.execute!(string[])("return ['zero', 'one', 'two'];");
            arr.length.should == 3;
            arr[0].should == "zero";
            arr[1].should == "one";
            arr[2].should == "two";
        });
    }
}
