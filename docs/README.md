# Documentation

Selenium is split into a WebDriver client and Grid server scaffolding:

- [WebDriver](webdriver/README.md) — install the client, start or connect a session, and use drivers, elements, roots, cookies, and logging.
- [Grid](grid/README.md) — work with Grid models and in-process hub, node, and routing primitives.

The Grid package does not yet include a live HTTP server, node registration heartbeat, or complete session distribution. Use `Driver.connect` when connecting the WebDriver client to an already running remote WebDriver server or Selenium Grid.

Project-level guides:

- [Testing](../TESTING.md)
- [Contributing](../CONTRIBUTING.md)

For protocol and upstream product documentation, see the [official Selenium documentation](https://www.selenium.dev/documentation/).
