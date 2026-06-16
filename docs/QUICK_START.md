# Quick Start

Selenium SDK is a D library for browser automation over the WebDriver protocol. It mirrors the usage patterns of the Selenium Ruby bindings so the API stays familiar, and most of the W3C surface maps to what you would expect. Where the library deviates from W3C, the caveat is documented inline and called out here.

This guide gets you from an empty project to driving a real browser. For the testing workflow see [TESTS.md](../TESTS.md), and for contribution guidelines see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Installation

Add the package with DUB:

```sh
dub add selenium-sdk
```

You also need a WebDriver server on your `PATH`. The library auto-detects the right one for the browser you ask for.

| Browser | WebDriver binary |
| --- | --- |
| Chrome | `chromedriver` |
| Firefox | `geckodriver` |
| Edge | `msedgedriver` |
| Safari | `safaridriver` |

The fastest possible start, letting the library pick the first installed driver on `PATH`:

```d
import selenium;

Driver driver = Driver.start();
scope (exit) driver.stop();

driver.go("https://example.com");
writeln(driver.title);
```

## Browsers

A `Browser` describes the capabilities you want from a session. The base `Browser` is generic; the concrete subclasses add vendor capabilities. Construct one, set fields, and hand it to `Driver.start`.

| Type | `browserName` | Notable extras |
| --- | --- | --- |
| `Browser` | generic | Standard W3C capabilities only. |
| `Chrome` | `chrome` | `binary`, `includeSwitches`, `excludeSwitches`, `prefs`, `extensions`, `logging`. |
| `Firefox` | `firefox` | `binary`, `args`, `prefs`, `profile`. |
| `Edge` | `MicrosoftEdge` | Chrome options plus `mobileEmulation`, WebView2 (`useWebView`). |
| `Safari` | `safari` | `automaticInspection`, `automaticProfiling`, `technologyPreview`. |

Standard capabilities live on the base and apply to every browser:

| Field | Purpose |
| --- | --- |
| `platform` | Requested host platform (`Platform.Windows`, `Platform.Linux`, ...). |
| `acceptInsecureCerts` | Accept invalid TLS certificates. |
| `pageLoadStrategy` | `Normal`, `Eager`, or `None`. |
| `unhandledPromptBehavior` | How to treat unexpected prompts. |
| `timeouts` | Implicit wait, page load, and script timeouts. |

```d
import selenium;
import core.time : seconds;

Chrome chrome = new Chrome();
chrome.binary = "/usr/bin/google-chrome";
chrome.includeSwitches = ["--headless=new", "--disable-gpu"];
chrome.timeouts.implicit = 5.seconds;

Driver driver = Driver.start(chrome);
scope (exit) driver.stop();
```

You can pass alternatives as a `firstMatch` list, and the server picks the first it can satisfy:

```d
Driver driver = Driver.start(new Chrome(), [new Firefox()]);
```

## Bridge

A `Bridge` is the low-level host that owns a WebDriver process or remote connection and manages every session on it. You usually do not touch it directly: `Driver.start` spawns one for you. Reach for a `Bridge` when you want to run multiple sessions over one process, cap concurrency, or attach to a remote endpoint.

Unlike most clients, a driver and a session are not strictly 1:1 here. A single `Bridge` can host many sessions, and each `Driver` is a handle to one of them.

| Member | Purpose |
| --- | --- |
| `Bridge.start(binary, args)` | Spawn a local driver process on a free port. |
| `Bridge.connect(address)` | Attach to an already running server (remote or grid). |
| `capacity` | Maximum concurrent sessions, or `0` for unlimited. |
| `sessions` | Active sessions keyed by id. |
| `stop()` | Kill a spawned process and drop all sessions. |

```d
import selenium;

// Share one driver process across two sessions.
Bridge bridge = Bridge.start(new Chrome().resolveBinary());
bridge.capacity = 2;

Driver first = Driver.start(bridge, new Chrome(), null);
Driver second = Driver.start(bridge, new Chrome(), null);
```

A `Bridge` created by `Bridge.start` owns its process and tears it down on collection. One created by `Bridge.connect` does not, so `stop` will not kill a remote server.

## Driver

The `Driver` is the primary way you use Selenium SDK. It wraps a single session and exposes a convenient API over the browser. Calls aim for high parity with the W3C specification and the Selenium Ruby bindings.

Stopping a driver ends only its own session and leaves the bridge alive for any others.

### Navigation

| Call | Action |
| --- | --- |
| `driver.go(url)` | Navigate to a URL. |
| `driver.back()` / `driver.forward()` | Move through history. |
| `driver.refresh()` | Reload the document. |
| `driver.url` | Current document URL. |
| `driver.title` | Current document title. |
| `driver.source` | Serialized page source. |
| `driver.screenshot` | Base64 PNG of the viewport. |

### Finding elements

Use a `By` locator with `find` for a single element or `findAll` for every match.

| Locator | Matches |
| --- | --- |
| `By.css(selector)` | CSS selector. |
| `By.xpath(expr)` | XPath expression. |
| `By.tagName(name)` | Tag name. |
| `By.linkText(text)` | Anchor with exact visible text. |
| `By.partialLinkText(text)` | Anchor containing the text. |

```d
Element button = driver.find(By.css("#submit"));
Element[] items = driver.findAll(By.xpath("//li[@class='item']"));
```

### Scripts and windows

```d
int sum = driver.execute!int("return arguments[0] + arguments[1];", JSONValue([2, 3]));

driver.window.maximize();
string[] handles = driver.window.handles();
string tab = driver.window.open("tab");
driver.window.switchTo(tab);

driver.frame.switchTo(0);
driver.frame.switchToParent();
```

### Cookies and logging

These are available per session but are not the focus of a quick start. In brief:

```d
import selenium;

driver.cookies.add(Cookie("session", "abc123"));
Cookie[] all = driver.cookies.all();
driver.cookies.clear();

driver.logger.drain(LogType.Browser); // pull pending remote logs
```

## Elements

An `Element` is a handle to a node in the page. It is valid only while that node stays attached to the DOM; stale handles raise `StaleElementReferenceException`.

| Member | Purpose |
| --- | --- |
| `text` | Rendered visible text. |
| `tagName` | Lowercased tag name. |
| `attribute(name)` | Markup attribute value. |
| `property(name)` | Live DOM property value. |
| `cssValue(name)` | Computed CSS value. |
| `size` / `position` | Bounding box dimensions and offset. |
| `selected` / `enabled` | Element state. |
| `click()` | Click the element. |
| `sendKeys(text...)` | Type into the element. |
| `clear()` | Clear an editable element. |
| `find(by)` / `findAll(by)` | Search within this element. |
| `screenshot` | Base64 PNG of the element. |

```d
Element form = driver.find(By.tagName("form"));
Element input = form.find(By.css("input[name='username']"));

input.sendKeys("alice");
writeln(input.attribute("placeholder"));
writeln(input.enabled);

form.find(By.css("button[type='submit']")).click();
```