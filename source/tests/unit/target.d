module tests.unit.target;

import selenium.browser : Browser, defaultBrowser;
import selenium.browser.chrome : Chrome;
import selenium.target : Platform, Target;

import core.time : msecs;

import std.json : JSONValue;

unittest
{
    Chrome chrome = new Chrome();
    chrome.acceptInsecureCerts = true;
    chrome.setWindowRect = true;
    auto target = new Target(chrome);
    JSONValue json = target.toJSONValue();
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
    auto target = new Target();
    target.platform = Platform.Windows;
    target.alwaysMatch = new Chrome();
    target.alwaysMatch.timeouts.implicit = 5000.msecs;
    JSONValue json = target.toJSONValue();
    assert("alwaysMatch" in json);
    assert(json["alwaysMatch"]["platformName"].str == "Windows");
    assert(json["alwaysMatch"]["timeouts"]["implicit"].get!long == 5000);
    assert("firstMatch" !in json);
}

unittest
{
    auto target = new Target();
    JSONValue json = target.toJSONValue();
    assert("alwaysMatch" in json);
    assert(json["alwaysMatch"]["browserName"].str == defaultBrowser.name);
    assert("firstMatch" !in json);
}
