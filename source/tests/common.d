module tests.common;

import std.uri : encodeComponent;
import selenium.bridge : Bridge;
import selenium.browser : Browser;
version(chrome)
    import selenium.browser.chrome : Chrome;
version(firefox)
    import selenium.browser.firefox : Firefox;
import selenium.driver : Driver;

string dataUri(string html)
    => "data:text/html;charset=utf-8,"~encodeComponent(html);


struct TestConfig
{
    Browser browser;
    Bridge bridge;
}

static TestConfig[] configs;

static this()
{
    version(chrome)
    {
        Chrome chrome = new Chrome();
        if (chrome.isInstalled)
        {
            // Useful for CI environments and avoiding a billion windows opening.
            chrome.includeSwitches = ["--no-sandbox", "--headless"];

            configs ~= TestConfig(
                chrome,
                Bridge.start(chrome.resolveBinary(), ["--log-level=OFF"])
            );
        }
    }

    version(firefox)
    {
        Firefox firefox = new Firefox();
        if (firefox.isInstalled)
        {
            firefox.args = ["--headless"];
            
            configs ~= TestConfig(
                firefox,
                Bridge.start(firefox.resolveBinary(), ["--log", "fatal"])
            );
        }
    }
}

shared static ~this()
{
    foreach (config; configs)
    {
        if (config.bridge !is null)
            config.bridge.stop();
    }
}

void testOnce(string browserName, void delegate(Driver driver) dg, bool fallback = true)
{
    foreach (config; configs)
    {
        if (config.browser.name != browserName)
            continue;

        Driver driver;
        driver = Driver.start(config.bridge, config.browser, null);
        scope (exit) driver.stop();
        dg(driver);
        return;
    }

    if (fallback)
        testOnce(configs[0].browser.name, dg, false);
}

void testAll(void delegate(Driver driver) dg)
{
    foreach (config; configs)
    {
        Driver driver;
        driver = Driver.start(config.bridge, config.browser, null);
        scope (exit) driver.stop();
        dg(driver);
    }
}