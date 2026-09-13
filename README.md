# Selenium

[![License](https://img.shields.io/badge/License-Apache%202.0-blue)](LICENSE.txt)
[![DUB Package](https://img.shields.io/badge/DUB-latest-red)](https://code.dlang.org/packages/selenium)
![Unit Tests](https://github.com/cetio/selenium/actions/workflows/unit-tests.yml/badge.svg)

| OS | Chrome | Firefox | Edge | Safari |
| --- | --- | --- | --- | --- |
| Ubuntu | ![Chrome / Ubuntu](https://github.com/cetio/selenium/actions/workflows/chrome-ubuntu.yml/badge.svg) | ![Firefox / Ubuntu](https://github.com/cetio/selenium/actions/workflows/firefox-ubuntu.yml/badge.svg) | | |
| macOS | ![Chrome / macOS](https://github.com/cetio/selenium/actions/workflows/chrome-macos.yml/badge.svg) | ![Firefox / macOS](https://github.com/cetio/selenium/actions/workflows/firefox-macos.yml/badge.svg) | | ![Safari / macOS](https://github.com/cetio/selenium/actions/workflows/safari-macos.yml/badge.svg) |
| Windows | ![Chrome / Windows](https://github.com/cetio/selenium/actions/workflows/chrome-windows.yml/badge.svg) | ![Firefox / Windows](https://github.com/cetio/selenium/actions/workflows/firefox-windows.yml/badge.svg) | ![Edge / Windows](https://github.com/cetio/selenium/actions/workflows/edge-windows.yml/badge.svg) | |

Selenium is a native D implementation of the W3C WebDriver protocol. It drives Chrome, Firefox, Edge, and Safari directly over HTTP, with no external language bindings or C wrappers. The API often mirrors the Selenium Ruby bindings, so it should be familiar to existing Selenium users.

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

## Documentation

- [Documentation index](docs/README.md)
- [WebDriver guide](docs/webdriver/README.md)
- [Grid guide](docs/grid/README.md)
- [Testing](TESTING.md)
- [Contributing](CONTRIBUTING.md)

## Roadmap

### WebDriver protocol

- [x] Fix Safari support (see integration tests)
- [ ] Asynchronous script execution (`POST /execute/async`)
- [ ] Actions API, including perform and release
- [x] Alert text, accept, dismiss, and prompt input commands
- [x] Computed accessibility role and label accessors
- [x] Page printing (`POST /print`)
- [ ] First-class timeout retrieval and updates
- [x] Full window rectangle support, including window position

### Client API

- [ ] Explicit waits with reusable expected conditions
- [ ] Special keys such as Enter, Tab, Escape, and arrows for `sendKeys`
- [ ] Convenience locators such as id, name, and class name
- [ ] Element display state (`isDisplayed`)
- [ ] Select-element helper

### Grid

- [ ] Live HTTP transport for hubs and nodes
- [ ] Node registration, heartbeat, draining, and removal
- [ ] Capability matching, session allocation, and command forwarding

### Quality

- [ ] Grid server and client (multi-session routing) tests
- [ ] W3C WebDriver compliance tests
- [ ] More than 70% code coverage for every source file

## License

Selenium is licensed under [Apache-2.0](LICENSE.txt).
