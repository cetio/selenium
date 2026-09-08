# WebDriver

The `selenium:webdriver` package is a native D client for the W3C WebDriver protocol. It can start a local WebDriver executable or connect to an existing remote endpoint.

- [Getting Started](GETTING_STARTED.md) — installation, browser capabilities, and an end-to-end example.
- [Bridge](BRIDGE.md) — local processes, remote connections, sessions, status, and low-level commands.
- [Driver](DRIVER.md) — navigation, elements, scripts, windows, frames, roots, cookies, and logging.
- [Elements](ELEMENTS.md) — locators, element state, interaction, scoped search, and shadow roots.

Supported browser capability classes are `Chrome`, `Firefox`, `Edge`, and `Safari`. The matching WebDriver executable must already be installed for local sessions. The library does not download it.

For the protocol and upstream Selenium guides, see the [official WebDriver documentation](https://www.selenium.dev/documentation/webdriver/).
