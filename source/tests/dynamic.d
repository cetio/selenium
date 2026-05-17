module tests.dynamic;

import selenium.driver : Driver;
import selenium.element : Element;
import selenium.errors : WebDriverConnectionError;
import selenium.locator;
import std.stdio : writeln;

unittest
{
    Driver driver;

    try
    {
        driver = Driver.start();
    }
    catch (WebDriverConnectionError)
    {
        writeln("SKIP: No WebDriver found in PATH.");
        return;
    }

    scope(exit)
        driver.quit();

    assert(driver.running);

    driver.navigate("http://example.com");
    assert(driver.url == "https://example.com/");

    Element heading = driver.findOne!"tag"("h1");
    assert(heading.text == "Example Domain");

    Element byCss = driver.findOne(byCss("h1"));
    assert(byCss !is null);
    assert(byCss.text == "Example Domain");

    Element link = driver.findOne!"tag"("a");
    assert(link !is null);

    writeln("PASS: dynamic integration test.");
}
