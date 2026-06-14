module tests.common;

import std.uri : encodeComponent;

string dataUri(string html)
    => "data:text/html;charset=utf-8,"~encodeComponent(html);

version(integration)
{
    import std.stdio : writeln;
    import selenium.bridge : Bridge;
    import selenium.browser : Browser;
    import selenium.browser.chrome : Chrome;
    import selenium.browser.firefox : Firefox;
    import selenium.driver : Driver;
    import selenium.exception : WebDriverConnectionException;

    struct TestConfig
    {
        Browser browser;
        Bridge bridge;
    }

    static TestConfig[] configs;

    static this()
    {
        Chrome chrome = new Chrome();
        if (chrome.isInstalled)
        {
            configs ~= TestConfig(
                chrome, 
                Bridge.start(chrome.resolveBinary(false), ["--log-level=OFF"])
            );
        }

        Firefox firefox = new Firefox();
        if (firefox.isInstalled)
        {
            configs ~= TestConfig(
                firefox, 
                Bridge.start(firefox.resolveBinary(false), ["--log", "fatal"])
            );
        }

        writeln("Running integration tests with ", configs.length, " browser(s).");
        foreach (config; configs)
            writeln("  - ", config.browser.name);
    }

    shared static ~this()
    {
        foreach (config; configs)
        {
            if (config.bridge !is null)
                config.bridge.stop();
        }
    }

    void testWithBrowsers(void delegate(Driver driver) dg)
    {
        foreach (config; configs)
        {
            Driver driver;
            driver = Driver.start(config.bridge, config.browser, null);
            scope (exit) driver.stop();
            dg(driver);
        }
    }
}