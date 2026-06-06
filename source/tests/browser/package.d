module tests.browser;

import selenium.browser : Browser, PageLoadStrategy, Platform, UnhandledPromptBehavior;
import selenium.browser.chrome : Chrome;
import selenium.browser.edge : Edge;
import selenium.browser.firefox : Firefox;
import selenium.browser.safari : Safari;

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
    assert(cast(Edge)browser is null);
    assert(cast(Firefox)browser is null);
    assert(cast(Safari)browser is null);
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
    JSONValue json = parseJSON(
        `{"browserName":"MicrosoftEdge","ms:edgeOptions":`
        ~`{"binary":"/usr/bin/edge","args":["--headless"],`
        ~`"debuggerAddress":"127.0.0.1:9222"}}`);
    Edge edge = cast(Edge)Browser.fromJSONValue(json);
    assert(edge !is null);
    assert(edge.name == "MicrosoftEdge");
    assert(edge.binary == "/usr/bin/edge");
    assert(edge.includeSwitches == ["--headless"]);
    assert(edge.debuggerAddress == "127.0.0.1:9222");
}

unittest
{
    Edge edge = new Edge();
    edge.release = "130";
    edge.binary = "/opt/edge";
    edge.includeSwitches = ["--inprivate"];
    edge.excludeSwitches = ["--enable-automation"];
    edge.debuggerAddress = "127.0.0.1:9222";
    edge.detach = true;
    edge.mobileEmulation = parseJSON(`{"deviceName":"iPhone X"}`);
    edge.wdpAddress = "127.0.0.1:50080";
    edge.wdpUsername = "user";
    edge.wdpPassword = "pass";
    edge.webviewOptions = parseJSON(`{"additionalBrowserArguments":["--foo"]}`);
    edge.windowsApp = "Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe!MSEDGE";

    Edge roundTrip = cast(Edge)Browser.fromJSONValue(edge.toJSON());
    assert(roundTrip.release == "130");
    assert(roundTrip.binary == "/opt/edge");
    assert(roundTrip.includeSwitches == ["--inprivate"]);
    assert(roundTrip.excludeSwitches == ["--enable-automation"]);
    assert(roundTrip.debuggerAddress == "127.0.0.1:9222");
    assert(roundTrip.detach == true);
    assert(roundTrip.mobileEmulation["deviceName"].str == "iPhone X");
    assert(roundTrip.wdpAddress == "127.0.0.1:50080");
    assert(roundTrip.wdpUsername == "user");
    assert(roundTrip.wdpPassword == "pass");
    assert(roundTrip.webviewOptions["additionalBrowserArguments"].array[0].str == "--foo");
    assert(roundTrip.windowsApp == "Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe!MSEDGE");
}

unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"safari","safari:automaticInspection":true,`
        ~`"safari:automaticProfiling":false}`);
    Safari safari = cast(Safari)Browser.fromJSONValue(json);
    assert(safari !is null);
    assert(safari.name == "safari");
    assert(safari.automaticInspection == true);
    assert(safari.automaticProfiling == false);
}

unittest
{
    Safari safari = new Safari();
    safari.automaticInspection = true;
    safari.automaticProfiling = true;
    safari.technologyPreview = true;

    Safari roundTrip = cast(Safari)Browser.fromJSONValue(safari.toJSON());
    assert(roundTrip.automaticInspection == true);
    assert(roundTrip.automaticProfiling == true);
    assert(roundTrip.name == "Safari Technology Preview");
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