# Quick Start

Selenium is a native D implementation of the W3C WebDriver protocol. It drives Chrome, Firefox, Edge, and Safari directly over HTTP. The `selenium:webdriver` package provides the client, and `selenium:grid` provides Grid models and in-process routing scaffolding.

For protocol concepts and upstream product documentation, see the [official Selenium documentation](https://www.selenium.dev/documentation/).

## Installation

Add the complete package or a specific subpackage with DUB:

```sh
dub add selenium
dub add selenium:webdriver
dub add selenium:grid
```

| Package | Contents |
| --- | --- |
| `selenium` | WebDriver and Grid modules. |
| `selenium:webdriver` | Bridge, driver, browser capabilities, elements, locators, roots, cookies, and logging. |
| `selenium:grid` | Grid models, hub and node scaffolding, and in-process HTTP routing. |

Install the browser and matching WebDriver executable separately, then put the executable on `PATH`:

| Browser | WebDriver executable |
| --- | --- |
| Chrome | `chromedriver` |
| Firefox | `geckodriver` |
| Edge | `msedgedriver` |
| Safari | `safaridriver` |

The library resolves executables but does not download or update them. `Driver.start()` scans the known executables in the table order and uses the first one found.

## First Program

```d
import selenium;

import std.stdio : writeln;

Driver driver = Driver.start(new Chrome());
scope (exit) driver.stop();

driver.go("https://example.com");
writeln(driver.title);
```

`Driver.start()` can instead select the first known WebDriver executable found on `PATH`. `driver.stop()` ends the session. See [WebDriver](webdriver/README.md) for browser capabilities, element interaction, remote sessions, and shared bridges.

## Grid

The `selenium:grid` package provides Grid status models, an in-process router, and hub and node scaffolding. It does not yet include a live HTTP server, node registration heartbeat, or complete session distribution.

```d
import selenium.grid;

Hub hub = Hub.start(4444, "my-secret");
scope (exit) hub.stop();
```

See [Grid](grid/README.md) for the implemented architecture, routes, and models.

## Next Steps

- [WebDriver](webdriver/README.md) for installation, browser capabilities, and an end-to-end example.
- [Bridge](webdriver/BRIDGE.md) for local processes, remote connections, sessions, status, and low-level commands.
- [Driver](webdriver/DRIVER.md) for navigation, scripts, windows, frames, roots, cookies, and logging.
- [Elements](webdriver/ELEMENTS.md) for locators, element state, interaction, scoped search, and shadow roots.
- [Actions](webdriver/ACTIONS.md) for W3C input sources and action sequences.
- [Grid](grid/README.md) for models, hub and node scaffolding, and in-process routing.
- [Testing](https://github.com/cetio/selenium/blob/master/TESTING.md) and [Contributing](https://github.com/cetio/selenium/blob/master/CONTRIBUTING.md) for development.
