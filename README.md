# Selenium

[![License](https://img.shields.io/badge/License-Apache%202.0-blue)](LICENSE.txt)
[![DUB Package](https://img.shields.io/badge/dub-package-red)](https://code.dlang.org/packages/selenium)

> [!CAUTION]
>
> At the time of writing this, some documentation and information (ie: about subpackages and availability) reflect changes that are not yet fully live!
>
> Subpackages are not live in source code, Dub still reflects prior Selenium-SDK naming, and many changes are only visible here.

Selenium is a native D implementation of the W3C WebDriver protocol. It drives Chrome, Firefox, Edge, and Safari directly over HTTP, with no external language bindings or C wrappers. The API often mirrors the Selenium Ruby bindings, so anyone who has used Selenium before will find it familiar.

A `Driver` is a handle to one session, and a `Bridge` is the connection that owns the WebDriver process. Unlike most clients, a bridge can host several sessions at once, and each driver is a handle to one of them.

## Packages

| Package | Contents |
| --- | --- |
| `selenium:webdriver` | Bridge, driver, browser capabilities, elements, roots, cookies, logging. |
| `selenium:grid` | Hub, node, slot and session models, HTTP routing. |

Add either or both with DUB:

```sh
dub add selenium:webdriver
dub add selenium:grid
```

Both subpackages are included when you depend on the root `selenium` package.

## Supported Browsers

| Browser | WebDriver binary |
| --- | --- |
| Chrome | `chromedriver` |
| Firefox | `geckodriver` |
| Edge | `msedgedriver` |
| Safari | `safaridriver` |

The library auto-detects the right driver for the browser you request, or picks the first one on `PATH` when you do not specify.

## Documentation

- [WebDriver](docs/webdriver/README.md) — Getting started, bridge, driver, elements.
- [Grid](docs/grid/README.md) — Getting started with hub and node.
- [Testing](TESTING.md) — Offline and integration test workflow.
- [Contributing](CONTRIBUTING.md) — How to report issues and submit changes.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines, and note that any new feature or bug fix is expected to ship with tests as described in [TESTING.md](TESTING.md).

## License

Selenium is licensed under [Apache-2.0](LICENSE.txt).
