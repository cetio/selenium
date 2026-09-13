/// Offline bridge tests: element reference parsing, response unwrapping, and capacity checks.
module tests.webdriver.driver.window;

import selenium.bridge : Bridge;
import selenium.browser : Browser, Platform;
import selenium.exception : WebDriverConnectionException;

import unit_threaded;

import std.json : JSONValue;
import core.time : msecs;

@Name("parseElementId W3C key")
unittest
{
    Bridge.parseElementId(
        JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("abc-123")])
    ).should == "abc-123";
}

@Name("parseElementId legacy ELEMENT key")
unittest
{
    Bridge.parseElementId(
        JSONValue(["ELEMENT": JSONValue("legacy-id")])
    ).should == "legacy-id";
}

@Name("parseElementId wrapped value")
unittest
{
    JSONValue wrapper = JSONValue.emptyObject;
    wrapper["value"] = JSONValue.emptyObject;
    wrapper["value"]["element-6066-11e4-a52e-4f735466cecf"] = JSONValue("wrapped-id");
    Bridge.parseElementId(wrapper).should == "wrapped-id";
}

@Name("parseElementIds array")
unittest
{
    JSONValue arr = JSONValue.emptyArray;
    arr.array ~= JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("e1")]);
    arr.array ~= JSONValue(["element-6066-11e4-a52e-4f735466cecf": JSONValue("e2")]);
    string[] ids = Bridge.parseElementIds(arr);
    ids.length.should == 2;
    ids[0].should == "e1";
    ids[1].should == "e2";
}

@Name("unwrapAndParse converts std.json values")
unittest
{
    JSONValue json = JSONValue(["value": JSONValue(["one", "two"])]);
    string[] ret = Bridge.unwrapAndParse!(string[])(json);
    ret.should == ["one", "two"];
    Bridge.unwrapAndParse!long(JSONValue(["value": JSONValue(2)])).should == 2;
}

@Name("bridge capacity rejects excess sessions before sending a request") @ShouldFailWith!WebDriverConnectionException
unittest
{
    Bridge bridge = new Bridge(1);
    bridge.sessions["active"] = new Browser();
    bridge.createSession(JSONValue.emptyObject);
}

@Name("bridge translates request failures to connection errors") @ShouldFailWith!WebDriverConnectionException
unittest
{
    Bridge bridge = new Bridge();
    bridge.address = "http://127.0.0.1:0";
    bridge.status();
}

@Name("failed session close remains retryable")
unittest
{
    Bridge bridge = new Bridge();
    bridge.address = "http://127.0.0.1:0";
    bridge.sessions["active"] = new Browser();

    bridge.closeSession("active").shouldThrow!WebDriverConnectionException;
    (("active" in bridge.sessions) !is null).should == true;
}

@Name("session creation accepts a custom timeout") @ShouldFailWith!WebDriverConnectionException
unittest
{
    Bridge bridge = new Bridge();
    bridge.address = "http://127.0.0.1:0";
    bridge.createSession(JSONValue.emptyObject, 1.msecs);
}

@Name("parseSession reads a W3C new-session response")
unittest
{
    JSONValue json = JSONValue([
        "value": JSONValue([
            "sessionId": JSONValue("sess-1"),
            "capabilities": JSONValue([
                "browserName": JSONValue("safari"),
                "platformName": JSONValue("Mac"),
                "acceptInsecureCerts": JSONValue(true),
            ]),
        ]),
    ]);

    string id;
    Browser browser = Bridge.parseSession(json, id);
    id.should == "sess-1";
    browser.name.should == "safari";
    (browser.platform == Platform.Mac).should == true;
    browser.acceptInsecureCerts.should == true;
}

@Name("parseSession rejects malformed new-session responses")
unittest
{
    void expectInvalid(JSONValue value)
    {
        string id;
        Bridge.parseSession(JSONValue(["value": value]), id).shouldThrow!WebDriverConnectionException;
    }

    expectInvalid(JSONValue([
        "capabilities": JSONValue.emptyObject,
    ]));
    expectInvalid(JSONValue([
        "sessionId": JSONValue(""),
        "capabilities": JSONValue.emptyObject,
    ]));
    expectInvalid(JSONValue([
        "sessionId": JSONValue(9),
        "capabilities": JSONValue.emptyObject,
    ]));
    expectInvalid(JSONValue([
        "sessionId": JSONValue("sess-1"),
    ]));
    expectInvalid(JSONValue([
        "sessionId": JSONValue("sess-1"),
        "capabilities": JSONValue(9),
    ]));
}

@Name("timeout synchronization is isolated per session")
unittest
{
    Bridge bridge = new Bridge();
    bridge.address = "http://127.0.0.1:0";
    Browser browser = new Browser();
    browser.timeouts.pageLoad = 100.msecs;
    bridge.sessions["first"] = browser;
    bridge.sessions["second"] = browser;
    bridge.timeoutSyncs["first"] = Bridge.TimeoutSync(0, 100, 0);

    bridge.ensureTimeoutsSynced("first", browser);

    bridge.ensureTimeoutsSynced("second", browser).shouldThrow!WebDriverConnectionException;
}

@Name("timeout synchronization sends zero resets")
unittest
{
    Bridge bridge = new Bridge();
    bridge.address = "http://127.0.0.1:0";
    Browser browser = new Browser();
    bridge.sessions["active"] = browser;
    bridge.timeoutSyncs["active"] = Bridge.TimeoutSync(0, 100, 0);

    bridge.ensureTimeoutsSynced("active", browser).shouldThrow!WebDriverConnectionException;
    bridge.timeoutSyncs["active"].page.should == 100;
}
