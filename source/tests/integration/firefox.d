/// Firefox integration tests.
///
/// This module is only compiled when `dub test --d-version=firefox` is used. It sets up a shared
/// Firefox session and mixes in `tests.common.BrowserIntegration` to exercise live browser behavior.
/// All shared tests use the module's `driver` accessor and must be `@Serial` because they share
/// the same live session.
module tests.integration.firefox;

version(firefox)
{
    import tests.common : BrowserIntegration, dataUri;
    import selenium.bridge : Bridge;
    import selenium.browser.firefox : Firefox;
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
        Firefox browser = new Firefox();
        browser.args = ["--headless"];
        Logger logger = new Logger();
        Bridge bridge = Bridge.start(browser.resolveBinary(), ["--log", "fatal"]);
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
