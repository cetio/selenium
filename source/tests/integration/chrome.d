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
    import selenium.browser : Browser;
    import selenium.browser.chrome : Chrome;
    import selenium.driver : Driver;
    import selenium.driver.logger : Logger, LogLevel;
    import selenium.element : By, Element, Size;
    import selenium.exception :
        ElementClickInterceptedException,
        ElementNotInteractableException,
        JavaScriptException,
        NoSuchShadowRootException,
        NoSuchWindowException,
        StaleElementReferenceException;
    import selenium.root : Root, RootType;

    import unit_threaded;

    import std.json : JSONValue, parseJSON;

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

    @Name("Chrome toJSON includes browserName and flags")
    unittest
    {
        Chrome chrome = new Chrome();
        chrome.acceptInsecureCerts = true;
        chrome.setWindowRect = true;

        JSONValue json = chrome.toJSON();
        json["browserName"].str.should == "chrome";
        json["acceptInsecureCerts"].should == JSONValue(true);
        json["setWindowRect"].should == JSONValue(true);
    }

    @Name("Chrome fromJSONValue parses options")
    unittest
    {
        JSONValue json = parseJSON(
            `{"browserName":"chrome","goog:chromeOptions":`
            ~`{"binary":"/usr/bin/chrome","args":["--headless"],`
            ~`"debuggerAddress":"127.0.0.1:9222"}}`);
        Chrome chrome = cast(Chrome)Browser.fromJSONValue(json);
        chrome.shouldNotBeNull;
        chrome.name.should == "chrome";
        chrome.binary.should == "/usr/bin/chrome";
        chrome.includeSwitches.should == ["--headless"];
        chrome.debuggerAddress.should == "127.0.0.1:9222";
    }

    @Name("Chrome roundtrips through toJSON/fromJSONValue")
    unittest
    {
        Chrome chrome = new Chrome();
        chrome.release = "120";
        chrome.binary = "/opt/chrome";
        chrome.includeSwitches = ["--incognito"];
        chrome.excludeSwitches = ["--enable-automation"];
        chrome.debuggerAddress = "127.0.0.1:9222";
        chrome.detach = true;

        Chrome roundTrip = cast(Chrome)Browser.fromJSONValue(chrome.toJSON());
        roundTrip.release.should == "120";
        roundTrip.binary.should == "/opt/chrome";
        roundTrip.includeSwitches.should == ["--incognito"];
        roundTrip.excludeSwitches.should == ["--enable-automation"];
        roundTrip.debuggerAddress.should == "127.0.0.1:9222";
        roundTrip.detach.should == true;
    }

    @Name("Chrome merges logging into Logger and serializes goog:loggingPrefs")
    unittest
    {
        Chrome chrome = new Chrome();
        chrome.binary = "/opt/chrome";
        chrome.logging["performance"] = LogLevel.all;

        Logger logger = new Logger();
        chrome.normalizeLogger(logger);
        logger.levels["performance"].should == LogLevel.all;

        JSONValue json = chrome.toJSON();
        json["goog:loggingPrefs"]["performance"].str.should == "ALL";

        Chrome roundTrip = cast(Chrome)Browser.fromJSONValue(json);
        roundTrip.shouldNotBeNull;
        roundTrip.logging["performance"].should == LogLevel.all;
    }
}
