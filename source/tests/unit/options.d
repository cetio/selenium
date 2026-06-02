module tests.unit.options;

import selenium.browser : Browser;
import selenium.browser.chrome : Chrome;
import selenium.options : Options;

import std.json : JSONType, JSONValue;

unittest
{
    JSONValue json = Options.init.toJSONValue();
    assert(json.type == JSONType.object);
    assert(json.object.length == 0);
}

unittest
{
    Chrome chrome = new Chrome();
    chrome.takesScreenshot = true;
    chrome.javascriptEnabled = true;
    Options options;
    options.browsers ~= chrome;
    JSONValue json = options.toJSONValue();
    assert("firstMatch" in json);
    assert(json["firstMatch"].array.length == 1);
    JSONValue first = json["firstMatch"].array[0];
    assert(first["browserName"].str == "chrome");
    assert(first["takesScreenshot"] == JSONValue(true));
    assert(first["javascriptEnabled"] == JSONValue(true));
}

unittest
{
    Options options;
    options.remoteSessionId = "sess-42";
    options.remoteQuietExceptions = true;
    JSONValue json = options.toJSONValue();
    assert("alwaysMatch" in json);
    assert(json["alwaysMatch"]["webdriver.remote.sessionid"].str == "sess-42");
    assert(json["alwaysMatch"]["webdriver.remote.quietExceptions"] == JSONValue(true));
    assert("remoteSessionId" !in json);
    assert("remoteQuietExceptions" !in json);
}