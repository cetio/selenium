/// Safari integration tests.
///
/// This module is only compiled when `dub test --d-version=safari` is used. It sets up a shared
/// Safari session and mixes in `tests.common.BrowserIntegration` to exercise live browser behavior.
/// All shared tests use the module's `driver` accessor and must be `@Serial` because they share
/// the same live session.
module tests.integration.safari;

version(safari)
{
    import tests.common : BrowserIntegration;
    import selenium.bridge : Bridge;
    import selenium.browser : Browser;
    import selenium.browser.safari : Safari;
    import selenium.driver : Driver;
    import selenium.driver.logger : Logger;

    import unit_threaded;

    import std.json : JSONValue, parseJSON;

private:
    shared Driver _driver;
    shared Safari _browser;

    Driver driver() => cast(Driver)_driver;
    Safari browser() => cast(Safari)_browser;

    shared static this()
    {
        _browser = cast(shared)new Safari();
        Logger logger = new Logger();
        Bridge bridge = Bridge.start(browser.resolveBinary());
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

    @Name("Safari toJSON includes browserName and options")
    unittest
    {
        Safari safari = new Safari();
        safari.acceptInsecureCerts = true;
        safari.automaticInspection = true;
        safari.automaticProfiling = true;

        JSONValue json = safari.toJSON();
        json["browserName"].str.should == "safari";
        json["acceptInsecureCerts"].should == JSONValue(true);
        json["safari:automaticInspection"].should == JSONValue(true);
        json["safari:automaticProfiling"].should == JSONValue(true);
    }

    @Name("Safari fromJSONValue parses options")
    unittest
    {
        JSONValue json = parseJSON(
            `{"browserName":"Safari Technology Preview",`
            ~`"safari:automaticInspection":true,`
            ~`"safari:automaticProfiling":true}`
        );
        Safari safari = cast(Safari)Browser.fromJSONValue(json);
        safari.shouldNotBeNull;
        safari.name.should == "Safari Technology Preview";
        safari.technologyPreview.should == true;
        safari.automaticInspection.should == true;
        safari.automaticProfiling.should == true;
    }

    @Name("Safari roundtrips through toJSON/fromJSONValue")
    unittest
    {
        Safari safari = new Safari();
        safari.acceptInsecureCerts = true;
        safari.automaticInspection = true;
        safari.automaticProfiling = true;
        safari.technologyPreview = true;

        Safari roundTrip = cast(Safari)Browser.fromJSONValue(safari.toJSON());
        roundTrip.acceptInsecureCerts.should == true;
        roundTrip.automaticInspection.should == true;
        roundTrip.automaticProfiling.should == true;
        roundTrip.technologyPreview.should == true;
        roundTrip.name.should == "Safari Technology Preview";
    }
}
