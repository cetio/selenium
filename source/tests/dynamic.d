module tests.dynamic;

import selenium.driver : Driver;
import selenium.element : Element;
import selenium.errors : WebDriverConnectionError;
import selenium.types : LocatorStrategy;

unittest
{
    Driver driver;

    try
        driver = Driver.start();
    catch (WebDriverConnectionError)
        return;

    scope(exit)
        driver.quit();

    assert(driver.bridge.running);

    driver.navigate("http://example.com");
    assert(driver.url == "https://example.com/");

    Element heading = driver.find(LocatorStrategy.TagName, "h1");
    assert(heading.text == "Example Domain");

    Element byCss = driver.find(LocatorStrategy.CssSelector, "h1");
    assert(byCss !is null);
    assert(byCss.text == "Example Domain");

    Element link = driver.find(LocatorStrategy.TagName, "a");
    assert(link !is null);
}
