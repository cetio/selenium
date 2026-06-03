module tests.browser;

import selenium.browser : Browser, Platform;
import selenium.browser.chrome : Chrome;

import core.time : msecs;

import std.json : JSONValue;

unittest
{
    Chrome chrome = new Chrome();
    chrome.acceptInsecureCerts = true;
    chrome.setWindowRect = true;

    JSONValue json = chrome.toJSONValue();
    assert(json["browserName"].str == "chrome");
    assert(json["acceptInsecureCerts"] == JSONValue(true));
    assert(json["setWindowRect"] == JSONValue(true));
}

unittest
{
    Browser browser = new Browser();
    browser.platform = Platform.Windows;
    browser.timeouts.implicit = 5000.msecs;

    JSONValue json = browser.toJSONValue();
    assert(json["platformName"].str == "Windows");
    assert(json["timeouts"]["implicit"].get!long == 5000);
}

unittest
{
    Browser browser = new Browser();
    JSONValue json = browser.toJSONValue();
    assert(json.object.length == 0);
}
