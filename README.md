# Selenium SDK

[![License](https://img.shields.io/badge/License-AGPL%20v3-blue)](LICENSE.txt)
[![DUB Package](https://img.shields.io/badge/dub-package-red?link=https%3A%2F%2Fcode.dlang.org%2Fpackages%2Fselenium-sdk)](https://code.dlang.org/packages/selenium-sdk)

Selenium SDK is a D SDK for browser automation over the WebDriver protocol. It manages the driver lifecycle, sessions, element interaction, script execution, and browser capabilities natively, without external language bindings. The API mirrors the Selenium Ruby bindings so it stays familiar to anyone who has used Selenium before.

## Features

- **Driver lifecycle** for Chrome, Firefox, Edge, and Safari, with automatic WebDriver detection on `PATH`.
- **Navigation and inspection** of page URL, title, source, and screenshots.
- **Element search and interaction** by CSS, XPath, tag name, and link text, globally or scoped to an element.
- **Script execution** with typed return values.
- **Window, tab, and frame management.**
- **Browser capabilities** configured through dedicated classes per browser.
- **Sessions and connections** managed by a low-level bridge, including remote endpoints and multiple sessions per process.

## Documentation

| Document | Contents |
| --- | --- |
| [Quick Start](docs/QUICK_START.md) | Install, configure a browser, and drive a session. |
| [Tests](TESTS.md) | Offline and integration testing workflow and conventions. |
| [Contributing](CONTRIBUTING.md) | How to report issues and submit changes. |

## Getting Started

Add the package to your project with `dub add selenium-sdk`, then install a WebDriver server (`chromedriver`, `geckodriver`, `msedgedriver`, or `safaridriver`) and make sure it is on your `PATH`. The [Quick Start](docs/QUICK_START.md) walks through a complete first session.

## Supported Browsers

| Browser | WebDriver binary |
| --- | --- |
| Chrome | `chromedriver` |
| Firefox | `geckodriver` |
| Edge | `msedgedriver` |
| Safari | `safaridriver` |

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines, and note that any new feature or bug fix is expected to ship with tests as described in [TESTS.md](TESTS.md).

## License

Selenium SDK is licensed under [AGPL-3.0](LICENSE.txt).
