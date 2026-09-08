# Selenium

[![License](https://img.shields.io/badge/License-Apache%202.0-blue)](LICENSE.txt)
[![DUB Package](https://img.shields.io/badge/dub-package-red)](https://code.dlang.org/packages/selenium)
[![Browser Integration](https://github.com/cetio/selenium/actions/workflows/browser-integration.yml/badge.svg)](https://github.com/cetio/selenium/actions/workflows/browser-integration.yml)

Selenium is a native D implementation of the W3C WebDriver protocol. It drives Chrome, Firefox, Edge, and Safari directly over HTTP, with no external language bindings or C wrappers. The API often mirrors the Selenium Ruby bindings, so it should be familiar to existing Selenium users.

A `Driver` is a handle to one browser session. A `Bridge` owns a local WebDriver process or connects to a remote server and can host multiple sessions.

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
| `selenium:webdriver` | Bridge, driver, browser capabilities, elements, roots, cookies, and logging. |
| `selenium:grid` | Grid models, hub and node scaffolding, and in-process HTTP routing. |

The Grid package currently provides models and routing primitives, not a live HTTP server or a complete session distributor.

## Quick Start

Install the browser and matching WebDriver executable, then ensure the driver is on `PATH`:

| Browser | WebDriver executable |
| --- | --- |
| Chrome | `chromedriver` |
| Firefox | `geckodriver` |
| Edge | `msedgedriver` |
| Safari | `safaridriver` |

```d
import selenium;

import std.stdio : writeln;

Driver driver = Driver.start(new Chrome());
scope (exit) driver.stop();

driver.go("https://example.com");
writeln(driver.title);
```

`Driver.start()` can instead select the first known WebDriver executable found on `PATH`. The library does not download browsers or drivers.

`import selenium;` publicly exposes the generic browser, Chrome, and Firefox APIs. Import `selenium.browser.edge` or `selenium.browser.safari` explicitly when using `Edge` or `Safari`.

## Documentation

- [Documentation index](docs/README.md)
- [WebDriver guide](docs/webdriver/README.md)
- [Grid guide](docs/grid/README.md)
- [Testing](TESTING.md)
- [Contributing](CONTRIBUTING.md)

## License

Selenium is licensed under [Apache-2.0](LICENSE.txt).
