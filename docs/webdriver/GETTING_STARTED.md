# Getting Started (WebDriver)

This guide gets you from an empty project to driving a real browser with general documentation and examples.

For the official Selenium WebDriver documentation and guides, see https://www.selenium.dev/documentation/webdriver/.

## Installation

Add the package with DUB:

```sh
dub add selenium
```

| Browser | WebDriver binary |
| --- | --- |
| Chrome | `chromedriver` |
| Firefox | `geckodriver` |
| Edge | `msedgedriver` |
| Safari | `safaridriver` |

This package does not automatically install drivers if you do not have them, so ensure you have a WebDriver server on your `PATH`. The library auto-detects the right one for the browser you ask for. 

The fastest possible start, letting the library pick the first installed driver on `PATH`:

```d
import selenium;

Driver driver = Driver.start();
scope (exit) driver.stop();

driver.go("https://example.com");
writeln(driver.title);
```

## First script

The official Selenium documentation breaks a script into eight basic components. Here is the same script in D and Ruby, side by side, so you can see how the API maps over.

| Step | D | Ruby |
| --- | --- | --- |
| 1. Start the session | `Driver driver = Driver.start(new Chrome());` | `driver = Selenium::WebDriver.for :chrome` |
| 2. Take action on browser | `driver.go("https://www.selenium.dev/selenium/web/web-form.html");` | `driver.get('https://www.selenium.dev/selenium/web/web-form.html')` |
| 3. Request browser information | `string title = driver.title;` | `title = driver.title` |
| 4. Establish waiting strategy | `chrome.timeouts.implicit = 500.msecs;` | `driver.manage.timeouts.implicit_wait = 500` |
| 5. Find an element | `Element textBox = driver.find(By.tagName("my-text"));` | `text_box = driver.find_element(tag_name: 'my-text')` |
| 6. Take action on element | `textBox.sendKeys("Selenium");` | `text_box.send_keys('Selenium')` |
| 7. Request element information | `string text = message.text;` | `text = message.text` |
| 8. End the session | `driver.stop();` | `driver.quit` |

The complete script in D:

```d
import selenium;
import selenium.browser.chrome : Chrome;
import core.time : msecs;
import std.stdio : writeln;

Chrome chrome = new Chrome();
chrome.timeouts.implicit = 500.msecs;

Driver driver = Driver.start(chrome);
scope (exit) driver.stop();

driver.go("https://www.selenium.dev/selenium/web/web-form.html");
writeln(driver.title);

Element textBox = driver.find(By.tagName("my-text"));
Element submitButton = driver.find(By.css("button"));

textBox.sendKeys("Selenium");
submitButton.click();

Element message = driver.find(By.css("#message"));
writeln(message.text);
```

The same script in Ruby:

```ruby
require 'selenium-webdriver'

driver = Selenium::WebDriver.for :chrome
driver.get('https://www.selenium.dev/selenium/web/web-form.html')
puts driver.title

driver.manage.timeouts.implicit_wait = 500
text_box = driver.find_element(tag_name: 'my-text')
submit_button = driver.find_element(css: 'button')

text_box.send_keys('Selenium')
submit_button.click

message = driver.find_element(id: 'message')
puts message.text

driver.quit
```

The naming is deliberately close. `Driver.start` replaces `Selenium::WebDriver.for`, `driver.go` replaces `driver.get`, and `driver.find(By.css(...))` replaces `driver.find_element(css: ...)`. The main difference is that timeouts are set on the `Browser` before the session starts, not on the driver afterwards.

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

In Ruby the same configuration looks like:

```ruby
options = Selenium::WebDriver::Options.chrome
options.binary = '/usr/bin/google-chrome'
options.add_argument('--headless=new')
options.add_argument('--disable-gpu')
options.timeouts.implicit_wait = 500

driver = Selenium::WebDriver.for :chrome, options: options
```

The D version sets fields directly on the `Chrome` object rather than chaining `add_argument` calls, but the capability names and values are the same.

You can pass alternatives as a `firstMatch` list, and the server picks the first it can satisfy:

```d
Driver driver = Driver.start(new Chrome(), [new Firefox()]);
```

## Bridge

A `Bridge` is the low-level host that owns a WebDriver process or remote connection and manages every session on it. You usually do not touch it directly: `Driver.start` spawns one for you. Reach for a `Bridge` when you want to run multiple sessions over one process or cap concurrency. To attach to a remote server or grid, use `Driver.connect`.

Unlike most clients, a driver and a session are not strictly 1:1 here. A single `Bridge` can host many sessions, and each `Driver` is a handle to one of them.

| Member | Purpose |
| --- | --- |
| `Bridge.start(binary, args, capacity)` | Spawn a local driver process on a free port. |
| `capacity` | Maximum concurrent sessions, fixed at construction, or `0` for unlimited. |
| `sessions` | Active sessions keyed by id. |
| `status()` | Server status from `GET /status`, as raw JSON. |
| `stop()` | Kill a spawned process and drop all sessions. |

```d
import selenium;

// Share one driver process across two sessions.
Bridge bridge = Bridge.start(new Chrome().resolveBinary(), null, 2);

Driver first = Driver.start(bridge, new Chrome(), null);
Driver second = Driver.start(bridge, new Chrome(), null);
```

A `Bridge` created by `Bridge.start` owns its process and tears it down on collection. A remote bridge created through `Driver.connect` does not, so `stop` will not kill the remote server.

## Driver

The `Driver` is the primary way you use Selenium SDK. It wraps a single session and exposes a convenient API over the browser. Calls aim for high parity with the W3C specification and the Selenium Ruby bindings.

Stopping a driver ends only its own session and leaves the bridge alive for any others.

### Remote connections

`Driver.connect` attaches to an already running WebDriver server or grid hub and starts a session on it. The backing `Bridge` has a capacity of 1, so only this driver's session may use it. The bridge does not own a process, so `stop` will not kill the remote server.

```d
import selenium;
import selenium.browser.chrome : Chrome;

Driver driver = Driver.connect("http://grid.example.com:4444", new Chrome());
scope (exit) driver.stop();

driver.go("https://example.com");
```

In Ruby, the equivalent is `Selenium::WebDriver.for :remote, url: 'http://grid.example.com:4444', capabilities: options`. The D version collapses the remote and local cases into `Driver.connect` and `Driver.start` respectively, both returning a `Driver`.

To inspect the server status, call `bridge.status()` on the driver's bridge. The raw JSON can be parsed into `selenium.grid.server.model.GridStatus` when connecting to a grid hub.

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

In Ruby these are `driver.find_element(css: '#submit')` and `driver.find_elements(xpath: "//li[@class='item']")`. The `By` struct in D serves the same role as the keyword arguments in Ruby, but is explicit about the strategy.

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