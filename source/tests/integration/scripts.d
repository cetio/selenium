module tests.integration.scripts;

import selenium.browser : Browser;
import selenium.driver : Driver;
import selenium.error : WebDriverConnectionError, WebDriverError;

import std.exception : assertThrown;

unittest
{
    Driver driver;
    driver = Driver.start();

    scope(exit)
        driver.stop();

    driver.navigate("about:blank");
    assert(driver.execute!int("return 42;") == 42);
}

unittest
{
    Driver driver;
    driver = Driver.start();

    scope(exit)
        driver.stop();

    driver.navigate("about:blank");
    assert(driver.execute!bool("return true;") == true);
}

unittest
{
    Driver driver;
    driver = Driver.start();

    scope(exit)
        driver.stop();

    driver.navigate("about:blank");
    assertThrown!WebDriverError(driver.execute("throw new Error('boom');"));
}
