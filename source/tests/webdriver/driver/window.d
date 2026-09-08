/// Offline bridge tests: element reference parsing, response unwrapping, and capacity checks.
module tests.webdriver.driver.window;

import selenium.bridge : Bridge;
import selenium.browser : Browser;
import selenium.exception : WebDriverConnectionException;

import unit_threaded;

import std.json : JSONValue;

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

@Name("bridge capacity rejects excess sessions before sending a request")
unittest
{
    Bridge bridge = new Bridge(1);
    bridge.sessions["active"] = new Browser();
    bridge.createSession(JSONValue.emptyObject).shouldThrow!WebDriverConnectionException;
    bridge.sessions.length.should == 1;
}
