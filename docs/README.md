---
layout: default
title: Documentation
nav_order: 1
permalink: /
---

# Documentation

Selenium is split into a WebDriver client and Grid server scaffolding:

- [WebDriver](webdriver/) — install the client, start or connect a session, and use drivers, elements, roots, cookies, and logging.
- [Grid](grid/) — work with Grid models and in-process hub, node, and routing primitives.

The Grid package does not yet include a live HTTP server, node registration heartbeat, or complete session distribution. Use `Driver.connect` when connecting the WebDriver client to an already running remote WebDriver server or Selenium Grid.

Project-level guides:

- [Testing](https://github.com/cetio/selenium/blob/master/TESTING.md)
- [Contributing](https://github.com/cetio/selenium/blob/master/CONTRIBUTING.md)

For protocol and upstream product documentation, see the [official Selenium documentation](https://www.selenium.dev/documentation/).
