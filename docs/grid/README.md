# Grid

The `selenium:grid` package provides Grid status models, an in-process router, and hub and node scaffolding. It is intended as a foundation for a D Grid implementation.

Current limitations are important:

- `Hub.start` and `Node.start` configure objects and route tables but do not listen on a network socket.
- Node registration and heartbeat behavior are not wired.
- Nodes advertise slot stereotypes but do not start their WebDriver bridges.
- New-session distribution and command forwarding are not implemented.
- Some lifecycle endpoints are placeholders, as described in the guide.

See [Getting Started](GETTING_STARTED.md) for the implemented model and routing surface.

To drive an already running Selenium Grid as a client, use `Driver.connect` from `selenium:webdriver`. That does not require this Grid subpackage.

For upstream Selenium Grid documentation, see the [official Grid documentation](https://www.selenium.dev/documentation/grid/).
