module tests.unit.capabilities;

import selenium.types : Capabilities;

import std.json : JSONType, JSONValue;

unittest
{
    JSONValue json = Capabilities.init.toJSONValue();
    assert(json.type == JSONType.object);
    assert(json.object.length == 0);
}

unittest
{
    Capabilities caps;
    caps.takesScreenshot = true;
    caps.javascriptEnabled = true;
    JSONValue json = caps.toJSONValue();
    assert(json.object.length == 2);
    assert(json["takesScreenshot"] == JSONValue(true));
    assert(json["javascriptEnabled"] == JSONValue(true));
}

unittest
{
    Capabilities caps;
    caps.remoteSessionId = "sess-42";
    caps.remoteQuietExceptions = true;
    JSONValue json = caps.toJSONValue();
    assert(json["webdriver.remote.sessionid"].str == "sess-42");
    assert(json["webdriver.remote.quietExceptions"] == JSONValue(true));
    assert("remoteSessionId" !in json);
    assert("remoteQuietExceptions" !in json);
}
