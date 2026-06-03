module tests.integration.scripts;

import selenium.browser : Browser;
import selenium.driver : Driver;
import selenium.error : JavaScriptError, WebDriverConnectionError;

import std.exception : assertThrown;

unittest
{
    Driver driver;
    driver = Driver.start();

    driver.go("about:blank");
    assert(driver.execute!int("return 42;") == 42);
    driver.stop();
}

unittest
{
    Driver driver;
    driver = Driver.start();

    driver.go("about:blank");
    assert(driver.execute!bool("return true;") == true);
    driver.stop();
}

unittest
{
    Driver driver;
    driver = Driver.start();

    driver.go("about:blank");
    assertThrown!JavaScriptError(driver.execute("throw new Error('boom');"));
    driver.stop();
}
