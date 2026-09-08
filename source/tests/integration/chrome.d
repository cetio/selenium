/// Chrome integration tests.
/// This module is only compiled when the `--d-version=chrome` flag is used.
///
/// All tests in this module which require use the driver instance must be `@Serial` because they
/// share live browser sessions.
module tests.integration.chrome;

version(chrome)
{
    import tests.common : BrowserIntegration, dataUri;
    import selenium.bridge : Bridge;
    import selenium.browser.chrome : Chrome;
    import selenium.driver : Driver;
    import selenium.driver.logger : Logger;
    import selenium.element : By, Element, Size;
    import selenium.exception : JavaScriptException, NoSuchShadowRootException, StaleElementReferenceException;
    import selenium.root : Root, RootType;

    import unit_threaded;

    import std.json : JSONValue;

private:
    shared static Driver driver;

    shared static this()
    {
        Chrome browser = new Chrome();
        browser.includeSwitches = ["--no-sandbox", "--headless"];
        Logger logger = new Logger();
        Bridge bridge = Bridge.start(browser.resolveBinary(), ["--log-level=OFF"]);
        driver = cast(shared)Driver.start(
            bridge,
            browser,
            null,
            logger
        );
    }

    shared static ~this()
    {
        if (driver is null)
            return;

        driver.stop();
        driver.bridge.stop();
    }

    mixin BrowserIntegration;
}
