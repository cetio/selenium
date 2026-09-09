/// Chrome integration tests.
///
/// This module is only compiled when `dub test --d-version=chrome` is used. It sets up a shared
/// Chrome session and mixes in `tests.common.BrowserIntegration` to exercise live browser behavior.
/// All shared tests use the module's `driver` accessor and must be `@Serial` because they share
/// the same live session.
module tests.integration.chrome;

version(chrome)
{
    import tests.common : BrowserIntegration, dataUri;
    import selenium.bridge : Bridge;
    import selenium.browser.chrome : Chrome;
    import selenium.driver : Driver;
    import selenium.driver.logger : Logger;
    import selenium.element : By, Element, Size;
    import selenium.exception :
        DetachedShadowRootException,
        ElementClickInterceptedException,
        ElementNotInteractableException,
        JavaScriptException,
        NoSuchShadowRootException,
        StaleElementReferenceException,
        UnexpectedAlertOpenException;
    import selenium.root : Root, RootType;

    import unit_threaded;

    import std.json : JSONValue;

private:
    shared Driver _driver;

    Driver driver() => cast(Driver)_driver;

    shared static this()
    {
        Chrome browser = new Chrome();
        browser.includeSwitches = ["--no-sandbox", "--headless"];
        Logger logger = new Logger();
        Bridge bridge = Bridge.start(browser.resolveBinary(), ["--log-level=OFF"]);
        _driver = cast(shared)Driver.start(
            bridge,
            browser,
            null,
            logger
        );
    }

    shared static ~this()
    {
        if (_driver is null)
            return;

        driver.stop();
        driver.bridge.stop();
    }

    mixin BrowserIntegration;
}
