module tests.browser;

import selenium.browser : Browser, PageLoadStrategy, Platform, UnhandledPromptBehavior;
import selenium.browser.chrome : Chrome;
import selenium.browser.firefox : Firefox;

import core.time : msecs;
import std.json;

// ========== Offline tests ==========

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
    browser.timeouts.implicit = 5_000.msecs;

    JSONValue json = browser.toJSON();
    assert(json["platformName"].str == "Windows");
    assert(json["timeouts"]["implicit"].get!long == 5_000);
}

unittest
{
    assert((new Browser()).toJSON().object.length == 0);
}

unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"chrome","goog:chromeOptions":`
        ~`{"binary":"/usr/bin/chrome","args":["--headless"],`
        ~`"debuggerAddress":"127.0.0.1:9222"}}`);
    Chrome chrome = cast(Chrome)Browser.fromJSONValue(json);
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
    Firefox firefox = cast(Firefox)Browser.fromJSONValue(json);
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

unittest
{
    Chrome chrome = new Chrome();
    chrome.release = "120";
    chrome.binary = "/opt/chrome";
    chrome.includeSwitches = ["--incognito"];
    chrome.excludeSwitches = ["--enable-automation"];
    chrome.debuggerAddress = "127.0.0.1:9222";
    chrome.detach = true;

    Chrome roundTrip = cast(Chrome)Browser.fromJSONValue(chrome.toJSON());
    assert(roundTrip.release == "120");
    assert(roundTrip.binary == "/opt/chrome");
    assert(roundTrip.includeSwitches == ["--incognito"]);
    assert(roundTrip.excludeSwitches == ["--enable-automation"]);
    assert(roundTrip.debuggerAddress == "127.0.0.1:9222");
    assert(roundTrip.detach == true);
}

unittest
{
    Firefox firefox = new Firefox();
    firefox.release = "121";
    firefox.binary = "/opt/firefox";
    firefox.args = ["--private"];
    firefox.profile = "YWJj"; // base64 for "abc"

    Firefox roundTrip = cast(Firefox)Browser.fromJSONValue(firefox.toJSON());
    assert(roundTrip.release == "121");
    assert(roundTrip.binary == "/opt/firefox");
    assert(roundTrip.args == ["--private"]);
    assert(roundTrip.profile == "YWJj");
}

unittest
{
    Browser browser = new Browser();
    browser.platform = Platform.Linux;
    browser.pageLoadStrategy = PageLoadStrategy.Eager;
    browser.unhandledPromptBehavior = UnhandledPromptBehavior.Dismiss;
    browser.timeouts.implicit = 1_000.msecs;
    browser.timeouts.pageLoad = 10_000.msecs;
    browser.timeouts.script = 30_000.msecs;

    Browser roundTrip = Browser.fromJSONValue(browser.toJSON());
    assert(roundTrip.pageLoadStrategy == PageLoadStrategy.Eager);
    assert(roundTrip.unhandledPromptBehavior == UnhandledPromptBehavior.Dismiss);
    assert(roundTrip.timeouts.implicit == 1_000.msecs);
    assert(roundTrip.timeouts.pageLoad == 10_000.msecs);
    assert(roundTrip.timeouts.script == 30_000.msecs);
}

version(integration)
{
    import selenium.driver : Driver;
    import tests.common;

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        assert(driver.id.length > 0);
        assert(driver.bridge !is null);
        assert(driver.browser !is null);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri("<html><title>BrowserInt</title><body></body></html>"));
        assert(driver.title == "BrowserInt");
    }
}
