/+ dub.sdl:
    dependency "selenium-d" path="."
+/

module example_google;

import selenium.driver;
import selenium.api;
import selenium.session;
import std.stdio;

void main()
{
    writeln("Starting chromedriver...");

    SeleniumDriver driver = new SeleniumDriver(DriverType.Chrome);
    driver.start();
    scope(exit)
    {
        writeln("Stopping chromedriver...");
        driver.stop();
    }

    writeln("Creating session...");
    immutable SeleniumSession session = driver.newSession(Capabilities.chrome);
    scope(exit)
    {
        writeln("Closing session...");
        session.close;
    }

    writeln("Navigating to google.com...");
    session.navigation.url("https://www.google.com");

    writeln("Current URL: ", session.navigation.url);
    writeln("Page title: ", session.currentWindow.title);

    writeln("Done.");
}
