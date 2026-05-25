module tests.integration.elements;

import selenium.driver : Driver;
import selenium.element : Element;
import selenium.error : NoSuchElementError, StaleElementReferenceError, WebDriverConnectionError;
import selenium.types : Locator;

import std.conv : to;
import std.exception : assertThrown;
import std.file : tempDir, write;
import std.path : buildPath;
import std.uuid : randomUUID;

private string makePage(string body_)
{
    string ret = buildPath(tempDir(), "selenium-sdk-"~randomUUID().to!string~".html");
    write(ret, "<html><body>"~body_~"</body></html>");
    return "file://"~ret;
}

private enum PAGE_A = "http://example.com/";
private enum PAGE_B = "http://example.org/";

unittest
{
    Driver driver;

    try
        driver = Driver.start();
    catch (WebDriverConnectionError)
        return;

    scope(exit)
        driver.quit();

    driver.navigate(PAGE_A);

    assertThrown!NoSuchElementError(
        driver.find(Locator.CssSelector, "#does-not-exist")
    );
}

unittest
{
    Driver driver;

    try
        driver = Driver.start();
    catch (WebDriverConnectionError)
        return;

    scope(exit)
        driver.quit();

    driver.navigate(PAGE_A);
    Element heading = driver.find(Locator.TagName, "h1");
    driver.navigate(PAGE_B);

    assertThrown!StaleElementReferenceError(heading.text);
}

unittest
{
    Driver driver;

    try
        driver = Driver.start();
    catch (WebDriverConnectionError)
        return;

    scope(exit)
        driver.quit();

    driver.navigate(PAGE_A);
    Element[] found = driver.findAll(Locator.CssSelector, ".no-such-class");
    assert(found.length == 0);
}

unittest
{
    Driver driver;

    try
        driver = Driver.start();
    catch (WebDriverConnectionError)
        return;

    scope(exit)
        driver.quit();

    driver.navigate(makePage("<input id='in' type='text'/>"));
    Element input = driver.find(Locator.CssSelector, "#in");
    input.click();
    Element active = driver.activeElement();
    assert(active !is null);
    assert(input.id == active.id);
}
