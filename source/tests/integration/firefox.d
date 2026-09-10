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
    import selenium.browser : Browser;
    import selenium.browser.firefox : Firefox;
    import selenium.driver : Driver;
    import selenium.driver.logger : Logger;
    import selenium.exception : UnsupportedOperationException;

    import unit_threaded;

    import std.json : JSONValue, parseJSON;

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

    @Name("Firefox rejects unsupported pointer cancellation")
    @Serial @ShouldFailWith!UnsupportedOperationException
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        JSONValue pointerCancel = JSONValue.emptyObject;
        pointerCancel["type"] = JSONValue("pointerCancel");

        JSONValue pointerSource = JSONValue.emptyObject;
        pointerSource["type"] = JSONValue("pointer");
        pointerSource["id"] = JSONValue("mouse");
        pointerSource["parameters"] = JSONValue(["pointerType": JSONValue("mouse")]);
        pointerSource["actions"] = JSONValue([pointerCancel]);

        driver.bridge.post!void(
            driver.id,
            "/actions",
            JSONValue(["actions": JSONValue([pointerSource])])
        );
    }

    @Name("Firefox fromJSONValue parses options")
    unittest
    {
        JSONValue json = parseJSON(
            `{"browserName":"firefox","moz:firefoxOptions":`
            ~`{"binary":"/usr/bin/firefox","args":["--private"],`
            ~`"profile":"base64abc"}}`);
        Firefox firefox = cast(Firefox)Browser.fromJSONValue(json);
        firefox.shouldNotBeNull;
        firefox.name.should == "firefox";
        firefox.binary.should == "/usr/bin/firefox";
        firefox.args.should == ["--private"];
        firefox.profile.should == "base64abc";
    }

    @Name("Firefox roundtrips through toJSON/fromJSONValue")
    unittest
    {
        Firefox firefox = new Firefox();
        firefox.release = "121";
        firefox.binary = "/opt/firefox";
        firefox.args = ["--private"];
        firefox.profile = "YWJj"; // base64 for "abc"

        Firefox roundTrip = cast(Firefox)Browser.fromJSONValue(firefox.toJSON());
        roundTrip.release.should == "121";
        roundTrip.binary.should == "/opt/firefox";
        roundTrip.args.should == ["--private"];
        roundTrip.profile.should == "YWJj";
    }
}
