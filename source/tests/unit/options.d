module tests.unit.options;

import selenium.browser : Browser;
import selenium.browser.chrome : Chrome;
import selenium.options : Options;

import std.json : JSONValue;

unittest
{
    Chrome chrome = new Chrome();
    chrome.acceptInsecureCerts = true;
    chrome.setWindowRect = true;
    Options options;
    options.browsers ~= chrome;
    JSONValue json = options.toJSONValue();
    assert("firstMatch" in json);
    assert(json["firstMatch"].array.length == 1);
    JSONValue first = json["firstMatch"].array[0];
    assert(first["browserName"].str == "chrome");
    assert(first["acceptInsecureCerts"] == JSONValue(true));
    assert(first["setWindowRect"] == JSONValue(true));
    assert("alwaysMatch" !in json);
}

unittest
{
    Options options;
    JSONValue json = options.toJSONValue();
    assert("alwaysMatch" !in json);
    assert("firstMatch" !in json);
}