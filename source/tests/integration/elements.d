module tests.integration.elements;

import selenium.browser : Browser;
import selenium.driver : Driver;
import selenium.element : By, Element;
import selenium.error : NoSuchElementError, StaleElementReferenceError, WebDriverConnectionError;

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
    driver = Driver.start();

    driver.navigate(PAGE_A);

    assertThrown!NoSuchElementError(
        driver.find(By.css("#does-not-exist"))
    );
    driver.stop();
}

unittest
{
    Driver driver;
    driver = Driver.start();

    driver.navigate(PAGE_A);
    Element heading = driver.find(By.tagName("h1"));
    driver.navigate(PAGE_B);

    assertThrown!StaleElementReferenceError(heading.text);
    driver.stop();
}

unittest
{
    Driver driver;
    driver = Driver.start();

    driver.navigate(PAGE_A);
    Element[] found = driver.findAll(By.css(".no-such-class"));
    assert(found.length == 0);
    driver.stop();
}

unittest
{
    Driver driver;
    driver = Driver.start();

    driver.navigate(makePage("<input id='in' type='text'/>"));
    Element input = driver.find(By.css("#in"));
    input.click();
    Element active = driver.activeElement();
    assert(active !is null);
    assert(input.id == active.id);
    driver.stop();
}
