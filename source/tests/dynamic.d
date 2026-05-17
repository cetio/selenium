module tests.dynamic;

import selenium.api;
import selenium.driver;
import selenium.session;
import std.process : execute;
import std.stdio : writeln;
import std.string : strip;

unittest
{
    string driverPath;
    DriverType driverType;

    if (execute(["which", "chromedriver"]).status == 0)
    {
        driverPath = execute(["which", "chromedriver"]).output.strip;
        driverType = DriverType.Chrome;
    }
    else if (execute(["which", "geckodriver"]).status == 0)
    {
        driverPath = execute(["which", "geckodriver"]).output.strip;
        driverType = DriverType.Firefox;
    }

    if (driverPath.length == 0)
    {
        writeln("SKIP: No WebDriver found in PATH.");
        return;
    }

    SeleniumDriver driver = new SeleniumDriver(driverType, driverPath);
    driver.start();
    scope(exit) driver.stop();

    assert(driver.isRunning);

    immutable SeleniumSession session = driver.newSession(Capabilities.chrome);
    scope(exit) session.close;

    session.navigation.url("http://example.com");
    assert(session.navigation.url == "https://example.com/");

    immutable Element heading = session.findOne(tagLocator("h1"));
    assert(heading.text == "Example Domain");

    writeln("PASS: dynamic integration test.");
}
