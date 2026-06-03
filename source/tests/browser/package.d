module tests.browser;

import selenium.browser : Browser, Platform;
import selenium.browser.chrome : Chrome;
import selenium.browser.firefox : Firefox;

import core.time : msecs;
import std.json;

unittest
{
    Chrome chrome = new Chrome();
    chrome.acceptInsecureCerts = true;
    chrome.setWindowRect = true;

    JSONValue json = chrome.toJSON();
    assert(json["browserName"].str == "chrome");
    assert(json["acceptInsecureCerts"] == JSONValue(true));
    assert(json["setWindowRect"] == JSONValue(true));
}

unittest
{
    Browser browser = new Browser();
    browser.platform = Platform.Windows;
    browser.timeouts.implicit = 5000.msecs;

    JSONValue json = browser.toJSON();
    assert(json["platformName"].str == "Windows");
    assert(json["timeouts"]["implicit"].get!long == 5000);
}

unittest
{
    Browser browser = new Browser();
    JSONValue json = browser.toJSON();
    assert(json.object.length == 0);
}

unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"chrome","goog:chromeOptions":`
        ~`{"binary":"/usr/bin/chrome","args":["--headless"],`
        ~`"debuggerAddress":"127.0.0.1:9222"}}`);
    Browser browser = Browser.fromJSONValue(json);
    Chrome chrome = cast(Chrome)browser;
    assert(chrome !is null);
    assert(chrome.name == "chrome");
    assert(chrome.binary == "/usr/bin/chrome");
    assert(chrome.includeSwitches == ["--headless"]);
    assert(chrome.debuggerAddress == "127.0.0.1:9222");
}

unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"firefox","moz:firefoxOptions":`
        ~`{"binary":"/usr/bin/firefox","args":["--private"],`
        ~`"profile":"base64abc"}}`);
    Browser browser = Browser.fromJSONValue(json);
    Firefox firefox = cast(Firefox)browser;
    assert(firefox !is null);
    assert(firefox.name == "firefox");
    assert(firefox.binary == "/usr/bin/firefox");
    assert(firefox.args == ["--private"]);
    assert(firefox.profile == "base64abc");
}

unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"MyCustomBrowser","platformName":"Linux",`
        ~`"acceptInsecureCerts":true,"setWindowRect":true}`);
    Browser browser = Browser.fromJSONValue(json);
    assert(cast(Chrome)browser is null);
    assert(cast(Firefox)browser is null);
    assert(browser.platform == Platform.Linux);
    assert(browser.acceptInsecureCerts == true);
    assert(browser.setWindowRect == true);
}
