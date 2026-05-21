module tests.unit.options;

import selenium.log : LogType;
import selenium.types : Options;

import std.json : JSONType, JSONValue;

unittest
{
    JSONValue json = Options.init.toJSONValue();
    assert(json.type == JSONType.object);
    assert(json.object.length == 0);
}

unittest
{
    Options options;
    options.takesScreenshot = true;
    options.javascriptEnabled = true;
    JSONValue json = options.toJSONValue();
    assert(json.object.length == 2);
    assert(json["takesScreenshot"] == JSONValue(true));
    assert(json["javascriptEnabled"] == JSONValue(true));
}

unittest
{
    Options options;
    options.remoteSessionId = "sess-42";
    options.remoteQuietExceptions = true;
    JSONValue json = options.toJSONValue();
    assert(json["webdriver.remote.sessionid"].str == "sess-42");
    assert(json["webdriver.remote.quietExceptions"] == JSONValue(true));
    assert("remoteSessionId" !in json);
    assert("remoteQuietExceptions" !in json);
}

unittest
{
    Options options;
    options.logTypes = LogType.Browser | LogType.Driver;
    options.logLevel = "INFO";
    JSONValue json = options.toJSONValue();
    assert("loggingPrefs" in json);
    assert(json["loggingPrefs"]["browser"].str == "INFO");
    assert(json["loggingPrefs"]["driver"].str == "INFO");
    assert("client" !in json["loggingPrefs"]);
    assert(json["goog:loggingPrefs"] == json["loggingPrefs"]);
}
