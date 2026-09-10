/// Edge integration tests.
///
/// This module is only compiled when `dub test --d-version=edge` is used. It sets up a shared
/// Edge session and mixes in `tests.common.BrowserIntegration` to exercise live browser behavior.
/// All shared tests use the module's `driver` accessor and must be `@Serial` because they share
/// the same live session.
module tests.integration.edge;

version(edge)
{
    import tests.common : BrowserIntegration;
    import selenium.bridge : Bridge;
    import selenium.browser : Browser;
    import selenium.browser.edge : Edge;
    import selenium.driver : Driver;
    import selenium.driver.logger : Logger, LogLevel;

    import unit_threaded;

    import std.json : JSONValue, parseJSON;

private:
    shared Driver _driver;
    shared Edge _browser;

    Driver driver() => cast(Driver)_driver;
    Edge browser() => cast(Edge)_browser;

    shared static this()
    {
        _browser = cast(shared)new Edge();
        _browser.includeSwitches = ["--headless"];

        Logger logger = new Logger();
        Bridge bridge = Bridge.start(
            browser.resolveBinary(),
            ["--log-level=OFF"]
        );

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

    @Name("Edge toJSON includes browserName and options")
    unittest
    {
        Edge edge = new Edge();
        edge.acceptInsecureCerts = true;
        edge.setWindowRect = true;
        edge.includeSwitches = ["--headless"];

        JSONValue json = edge.toJSON();
        json["browserName"].str.should == "MicrosoftEdge";
        json["acceptInsecureCerts"].should == JSONValue(true);
        json["setWindowRect"].should == JSONValue(true);
        json["ms:edgeOptions"]["args"].should == JSONValue(["--headless"]);
    }

    @Name("Edge fromJSONValue parses options")
    unittest
    {
        JSONValue json = parseJSON(
            `{"browserName":"MicrosoftEdge","ms:edgeOptions":`
            ~`{"binary":"/usr/bin/edge","args":["--headless"],`
            ~`"debuggerAddress":"127.0.0.1:9222"}}`
        );
        Edge edge = cast(Edge)Browser.fromJSONValue(json);
        edge.shouldNotBeNull;
        edge.name.should == "MicrosoftEdge";
        edge.binary.should == "/usr/bin/edge";
        edge.includeSwitches.should == ["--headless"];
        edge.debuggerAddress.should == "127.0.0.1:9222";
    }

    @Name("Edge roundtrips through toJSON/fromJSONValue")
    unittest
    {
        Edge edge = new Edge();
        edge.release = "120";
        edge.binary = "/opt/edge";
        edge.includeSwitches = ["--incognito"];
        edge.excludeSwitches = ["--enable-automation"];
        edge.debuggerAddress = "127.0.0.1:9222";
        edge.detach = true;

        Edge roundTrip = cast(Edge)Browser.fromJSONValue(edge.toJSON());
        roundTrip.release.should == "120";
        roundTrip.binary.should == "/opt/edge";
        roundTrip.includeSwitches.should == ["--incognito"];
        roundTrip.excludeSwitches.should == ["--enable-automation"];
        roundTrip.debuggerAddress.should == "127.0.0.1:9222";
        roundTrip.detach.should == true;
    }

    @Name("Edge merges logging into Logger and serializes goog:loggingPrefs")
    unittest
    {
        Edge edge = new Edge();
        edge.binary = "/opt/edge";
        edge.logging["performance"] = LogLevel.all;

        Logger logger = new Logger();
        edge.normalizeLogger(logger);
        logger.levels["performance"].should == LogLevel.all;

        JSONValue json = edge.toJSON();
        json["goog:loggingPrefs"]["performance"].str.should == "ALL";

        Edge roundTrip = cast(Edge)Browser.fromJSONValue(json);
        roundTrip.shouldNotBeNull;
        roundTrip.logging["performance"].should == LogLevel.all;
    }
}
