module tests.browser;

import selenium.browser : Browser, PageLoadStrategy, Platform, UnhandledPromptBehavior;
import selenium.browser.chrome : Chrome;
import selenium.browser.edge : Edge;
import selenium.browser.firefox : Firefox;
import selenium.browser.safari : Safari;

import unit_threaded;

import core.time : msecs;
import std.json;

// ========== Offline tests ==========

@Name("Chrome toJSON includes browserName and flags")
unittest
{
    Chrome chrome = new Chrome();
    chrome.acceptInsecureCerts = true;
    chrome.setWindowRect = true;

    JSONValue json = chrome.toJSON();
    json["browserName"].str.should == "chrome";
    json["acceptInsecureCerts"].should == JSONValue(true);
    json["setWindowRect"].should == JSONValue(true);
}

@Name("Browser toJSON includes platform and timeouts")
unittest
{
    Browser browser = new Browser();
    browser.platform = Platform.Windows;
    browser.timeouts.implicit = 5_000.msecs;

    JSONValue json = browser.toJSON();
    json["platformName"].str.should == "Windows";
    json["timeouts"]["implicit"].get!long.should == 5_000;
}

@Name("Empty Browser toJSON has no keys")
unittest
{
    (new Browser()).toJSON().object.length.should == 0;
}

@Name("Chrome fromJSONValue parses options")
unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"chrome","goog:chromeOptions":`
        ~`{"binary":"/usr/bin/chrome","args":["--headless"],`
        ~`"debuggerAddress":"127.0.0.1:9222"}}`);
    Chrome chrome = cast(Chrome)Browser.fromJSONValue(json);
    chrome.shouldNotBeNull;
    chrome.name.should == "chrome";
    chrome.binary.should == "/usr/bin/chrome";
    chrome.includeSwitches.should == ["--headless"];
    chrome.debuggerAddress.should == "127.0.0.1:9222";
}

@Name("Firefox fromJSONValue parses options")
unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"firefox","moz:firefoxOptions":`
        ~`{"binary":"/usr/bin/firefox","args":["--private"],`
        ~`"profile":"base64abc"}}`);
    Firefox firefox = cast(Firefox)Browser.fromJSONValue(json);
    firefox.shouldNotBeNull;
    firefox.name.should == "firefox";
    firefox.binary.should == "/usr/bin/firefox";
    firefox.args.should == ["--private"];
    firefox.profile.should == "base64abc";
}

@Name("Custom browser fromJSONValue roundtrips")
unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"MyCustomBrowser","platformName":"Linux",`
        ~`"acceptInsecureCerts":true,"setWindowRect":true}`);
    Browser browser = Browser.fromJSONValue(json);
    (cast(Chrome)browser).shouldBeNull;
    (cast(Edge)browser).shouldBeNull;
    (cast(Firefox)browser).shouldBeNull;
    (cast(Safari)browser).shouldBeNull;
    browser.platform.should == Platform.Linux;
    browser.acceptInsecureCerts.should == true;
    browser.setWindowRect.should == true;
}

@Name("Chrome roundtrips through toJSON/fromJSONValue")
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
    roundTrip.release.should == "120";
    roundTrip.binary.should == "/opt/chrome";
    roundTrip.includeSwitches.should == ["--incognito"];
    roundTrip.excludeSwitches.should == ["--enable-automation"];
    roundTrip.debuggerAddress.should == "127.0.0.1:9222";
    roundTrip.detach.should == true;
}

@Name("Firefox roundtrips through toJSON/fromJSONValue")
unittest
{
    Firefox firefox = new Firefox();
    firefox.release = "121";
    firefox.binary = "/opt/firefox";
    firefox.args = ["--private"];
    firefox.profile = "YWJj"; // base64 for "abc"

    Firefox roundTrip = cast(Firefox)Browser.fromJSONValue(firefox.toJSON());
    roundTrip.release.should == "121";
    roundTrip.binary.should == "/opt/firefox";
    roundTrip.args.should == ["--private"];
    roundTrip.profile.should == "YWJj";
}

@Name("Edge fromJSONValue parses options")
unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"MicrosoftEdge","ms:edgeOptions":`
        ~`{"binary":"/usr/bin/edge","args":["--headless"],`
        ~`"debuggerAddress":"127.0.0.1:9222"}}`);
    Edge edge = cast(Edge)Browser.fromJSONValue(json);
    edge.shouldNotBeNull;
    edge.name.should == "MicrosoftEdge";
    edge.binary.should == "/usr/bin/edge";
    edge.includeSwitches.should == ["--headless"];
    edge.debuggerAddress.should == "127.0.0.1:9222";
}

@Name("Edge roundtrips through toJSON/fromJSONValue")
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
    roundTrip.release.should == "130";
    roundTrip.binary.should == "/opt/edge";
    roundTrip.includeSwitches.should == ["--inprivate"];
    roundTrip.excludeSwitches.should == ["--enable-automation"];
    roundTrip.debuggerAddress.should == "127.0.0.1:9222";
    roundTrip.detach.should == true;
    roundTrip.mobileEmulation["deviceName"].str.should == "iPhone X";
    roundTrip.wdpAddress.should == "127.0.0.1:50080";
    roundTrip.wdpUsername.should == "user";
    roundTrip.wdpPassword.should == "pass";
    roundTrip.webviewOptions["additionalBrowserArguments"].array[0].str.should == "--foo";
    roundTrip.windowsApp.should == "Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe!MSEDGE";
}

@Name("Safari fromJSONValue parses options")
unittest
{
    JSONValue json = parseJSON(
        `{"browserName":"safari","safari:automaticInspection":true,`
        ~`"safari:automaticProfiling":false}`);
    Safari safari = cast(Safari)Browser.fromJSONValue(json);
    safari.shouldNotBeNull;
    safari.name.should == "safari";
    safari.automaticInspection.should == true;
    safari.automaticProfiling.should == false;
}

@Name("Safari roundtrips through toJSON/fromJSONValue")
unittest
{
    Safari safari = new Safari();
    safari.automaticInspection = true;
    safari.automaticProfiling = true;
    safari.technologyPreview = true;

    Safari roundTrip = cast(Safari)Browser.fromJSONValue(safari.toJSON());
    roundTrip.automaticInspection.should == true;
    roundTrip.automaticProfiling.should == true;
    roundTrip.name.should == "Safari Technology Preview";
}

@Name("Browser roundtrips platform, strategy, and timeouts")
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
    roundTrip.pageLoadStrategy.should == PageLoadStrategy.Eager;
    roundTrip.unhandledPromptBehavior.should == UnhandledPromptBehavior.Dismiss;
    roundTrip.timeouts.implicit.should == 1_000.msecs;
    roundTrip.timeouts.pageLoad.should == 10_000.msecs;
    roundTrip.timeouts.script.should == 30_000.msecs;
}