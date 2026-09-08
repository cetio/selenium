# Getting Started with WebDriver

This guide starts a local browser session with the `selenium:webdriver` package. The client implements the W3C WebDriver protocol and communicates directly with a WebDriver server over HTTP.

For protocol concepts and upstream guides, see the [official WebDriver documentation](https://www.selenium.dev/documentation/webdriver/).

## Installation

Add the WebDriver subpackage or the complete package:

```sh
dub add selenium:webdriver
# Or: dub add selenium
```

Install the browser and matching WebDriver executable separately, and put the executable on `PATH`:

| Browser | Class | WebDriver executable |
| --- | --- | --- |
| Chrome | `Chrome` | `chromedriver` |
| Firefox | `Firefox` | `geckodriver` |
| Edge | `Edge` | `msedgedriver` |
| Safari | `Safari` | `safaridriver` |

The library resolves executables but does not download or update them. `Driver.start()` scans the known executables in the table order and uses the first one found.

The `selenium` module publicly imports `Browser`, `Chrome`, `Firefox`, `Driver`, `Bridge`, elements, roots, cookies, logging, and exceptions. Import Edge and Safari explicitly:

```d
import selenium.browser.edge : Edge;
import selenium.browser.safari : Safari;
```

## First Program

```d
import selenium;

import std.stdio : writeln;

Chrome browser = new Chrome();
Driver driver = Driver.start(browser);
scope (exit) driver.stop();

driver.go("https://example.com");
writeln(driver.title);
```

`Driver.start(browser)` resolves the browser's WebDriver executable, starts it on a free loopback port, waits for it to become ready, and creates a session. `driver.stop()` ends that session. The underlying local bridge owns the WebDriver process and stops it when collected. Use an explicit `Bridge` when process lifetime must be controlled directly.

## Interacting with a Page

```d
import selenium;

import core.time : msecs;
import std.stdio : writeln;

Chrome browser = new Chrome();
browser.timeouts.implicit = 500.msecs;

Driver driver = Driver.start(browser);
scope (exit) driver.stop();

driver.go("https://www.selenium.dev/selenium/web/web-form.html");

Element textBox = driver.find(By.tagName("my-text"));
Element submitButton = driver.find(By.css("button"));
textBox.sendKeys("Selenium");
submitButton.click();

Element message = driver.find(By.css("#message"));
writeln(message.text);
```

The API follows familiar Selenium concepts: `driver.go` navigates, `find` and `findAll` accept a `By` locator, and an `Element` exposes interaction and state methods. Timeouts are configured on the browser capabilities object. Changes made to `driver.browser.timeouts` after session creation are synchronized lazily before commands that use them.

## Browser Capabilities

`Browser` contains standard W3C capabilities shared by every concrete browser class.

| Field | Purpose |
| --- | --- |
| `platform` | Requested host platform: `Any`, `Windows`, `Linux`, `Mac`, or `Android`. |
| `acceptInsecureCerts` | Accept invalid TLS certificates. |
| `pageLoadStrategy` | `Normal`, `Eager`, or `None`. |
| `setWindowRect` | Request support for resizing and positioning windows. |
| `strictFileInteractability` | Enforce file-input interactability checks. |
| `unhandledPromptBehavior` | Dismiss, accept, notify, or ignore unexpected prompts. |
| `timeouts.implicit` | Element-location wait. |
| `timeouts.pageLoad` | Navigation wait. |
| `timeouts.script` | Script-execution wait. |

Concrete classes add vendor capabilities:

| Class | Vendor capabilities |
| --- | --- |
| `Chrome` | Release, binary, included and excluded switches, local and user preferences, extensions, debugger address, Linux minidumps, detach mode, and logging preferences. |
| `Firefox` | Release, binary, launch arguments, user preferences, and a profile directory or base64 archive. |
| `Edge` | Chromium options plus mobile emulation, Windows Device Portal, WebView2 options, Windows app ID, and WebView mode. |
| `Safari` | Automatic inspection, automatic profiling, and Safari Technology Preview. |

```d
import selenium;

import core.time : seconds;

Chrome browser = new Chrome();
browser.binary = "/usr/bin/google-chrome";
browser.includeSwitches = ["--headless", "--disable-gpu"];
browser.acceptInsecureCerts = true;
browser.timeouts.implicit = 5.seconds;

Driver driver = Driver.start(browser);
scope (exit) driver.stop();
```

### Alternative Capabilities

Pass a `firstMatch` list after the required `alwaysMatch` browser. The server chooses an acceptable combination:

```d
Driver driver = Driver.start(new Chrome(), [new Firefox()]);
scope (exit) driver.stop();
```

The executable is resolved from `alwaysMatch`. Alternatives do not cause the client to launch a different WebDriver executable.

## Remote Sessions

Connect to an already running standalone WebDriver server or Selenium Grid with `Driver.connect`:

```d
import selenium;

Driver driver = Driver.connect("http://grid.example.com:4444", new Chrome());
scope (exit) driver.stop();

driver.go("https://example.com");
```

The remote bridge has capacity one and does not own a process. Stopping the driver deletes its session but does not stop the remote server.

## Sharing a Local WebDriver Process

Use an explicit bridge to control process lifetime or host multiple sessions:

```d
import selenium;

Chrome browser = new Chrome();
Bridge bridge = Bridge.start(browser.resolveBinary(), null, 2);
scope (exit) bridge.stop();

Driver first = Driver.start(bridge, browser, null);
scope (exit) first.stop();

Driver second = Driver.start(bridge, new Chrome(), null);
scope (exit) second.stop();
```

A positive bridge capacity limits concurrent sessions. Zero means unlimited.

## Next Steps

- [Bridge](BRIDGE.md) — process ownership, sessions, status, and low-level requests.
- [Driver](DRIVER.md) — navigation, scripts, windows, frames, roots, cookies, and logging.
- [Elements](ELEMENTS.md) — locators, state, interaction, descendant search, and shadow roots.
- [Testing](../../TESTING.md) — offline and browser integration tests.
