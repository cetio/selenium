# Getting Started (Grid)

This guide covers the grid server scaffolding: hub, node, and the models that flow between them.

For the official Selenium Grid documentation, see https://www.selenium.dev/documentation/grid/.

## Overview

A grid distributes WebDriver sessions across multiple machines. A `Hub` is the coordinator that routes requests and tracks the node registry. A `Node` is the worker that hosts WebDriver slots and serves node-level endpoints.

The hub does not host WebDriver sessions itself. It forwards new session requests to a matching node and tracks which node owns each session. A node hosts one or more slots, each backed by a `Bridge` and advertising a capability stereotype.

This package provides the routing and modeling surface for a grid. It does not include a live HTTP server loop, so the routing surface can be exercised and tested without sockets.

## Hub

`Hub.start` configures a hub on a given port and registers its route table.

```d
import selenium.grid.server.hub : Hub;

Hub hub = Hub.start(4444, "my-secret");
```

| Parameter | Purpose |
| --- | --- |
| `port` | The port the hub advertises in its address. |
| `secret` | The registration secret, or null for an open grid. |

| Endpoint | Method | Action |
| --- | --- | --- |
| `/status` | GET | Grid readiness and node registry. |
| `/session/<sessionId>` | DELETE | Drop a session from the registry. |
| `/se/grid/distributor/node/<nodeId>` | DELETE | Remove a node (requires secret). |
| `/se/grid/distributor/node/<nodeId>/drain` | POST | Mark a node as draining (requires secret). |

```d
import selenium.grid.server.model : GridStatus;

GridStatus status = hub.status();
writeln(status.ready);
foreach (node; status.nodes)
    writeln(node.id, ": ", node.availability);
```

## Node

`Node.start` configures a node with one slot per browser and registers its route table.

```d
import selenium.grid.server.node : Node;
import selenium.browser.chrome : Chrome;
import selenium.browser.firefox : Firefox;

Node node = Node.start([new Chrome(), new Firefox()], "http://127.0.0.1:4444", 5555, "my-secret");
```

| Parameter | Purpose |
| --- | --- |
| `slotBrowsers` | One browser per slot, defining each slot's stereotype. |
| `hubAddress` | The hub URL to register with, or null for standalone. |
| `port` | The port the node advertises in its address. |
| `secret` | The registration secret shared with the hub, or null. |

| Endpoint | Method | Action |
| --- | --- | --- |
| `/status` | GET | Node status and slot table. |
| `/se/grid/node/drain` | POST | Drain the node (requires secret). |
| `/se/grid/node/owner/<sessionId>` | GET | Check if the node owns a session (requires secret). |
| `/se/grid/node/session/<sessionId>` | DELETE | Free a slot by session id (requires secret). |

## Models

The grid models mirror the wire envelope shapes and roundtrip through `toJSON` and `fromJSON`.

| Type | Purpose |
| --- | --- |
| `GridStatus` | Grid-level status with readiness, message, and node list. |
| `NodeInfo` | Node status with id, URI, max sessions, availability, OS info, and slots. |
| `Slot` | A single execution slot with id, stereotype, and optional session. |
| `Stereotype` | The capability object advertised for a slot. |
| `SessionInfo` | A session tracked by the hub, mapped to its owning node. |
| `Availability` | Node availability: `Up`, `Down`, or `Draining`. |

## Connecting to a grid

From the client side, use `Driver.connect` to attach to a running grid hub and start a session on it. The backing `Bridge` has a capacity of 1, so only the connecting session may use it.

```d
import selenium;
import selenium.browser.chrome : Chrome;

Driver driver = Driver.connect("http://127.0.0.1:4444", new Chrome());
scope (exit) driver.stop();

driver.go("https://example.com");
```

To inspect the grid status from the client side, call `bridge.status()` and parse the raw JSON into `GridStatus`:

```d
import selenium.grid.server.model : GridStatus;

GridStatus status = GridStatus.fromJSON(driver.bridge.status());
writeln(status.ready ? "Grid ready." : "Grid not ready.");
```