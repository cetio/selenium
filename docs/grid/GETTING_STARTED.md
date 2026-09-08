# Getting Started with Grid

The `selenium:grid` package currently provides data models and in-process routing scaffolding for a future Grid server. It does not provide a live HTTP listener or a complete session distributor.

For upstream Selenium Grid deployment and operation, see the [official Grid documentation](https://www.selenium.dev/documentation/grid/).

## Installation

Add the Grid subpackage with DUB:

```sh
dub add selenium:grid
```

Importing `selenium.grid` exposes the hub, node, router, and model APIs:

```d
import selenium.grid;
```

## Implemented Architecture

A `Hub` owns an in-memory node registry, session ownership map, and route table. A `Node` owns an in-memory slot table and route table. Each configured browser creates one advertised slot stereotype.

`Hub.start` and `Node.start` only construct these objects. They do not bind ports, receive HTTP requests, register nodes, launch WebDriver processes, or distribute new sessions. An application embedding this package must supply those transport and lifecycle layers.

## Hub

`Hub.start` sets the advertised loopback address and registers the implemented routes:

```d
import selenium.grid;

Hub hub = Hub.start(4444, "my-secret");
scope (exit) hub.stop();
```

| Parameter | Purpose |
| --- | --- |
| `port` | Port included in the advertised `http://127.0.0.1:<port>` address. Defaults to `4444`. |
| `secret` | Registration secret, or `null` for unsecured protected routes. |

| Route | Method | Current behavior |
| --- | --- | --- |
| `/status` | GET | Returns status built from the in-memory node registry. |
| `/session/<sessionId>` | DELETE | Removes a known session from the hub map. it does not forward the command. |
| `/se/grid/distributor/node/<nodeId>` | DELETE | Removes a registered node after checking the secret. |
| `/se/grid/distributor/node/<nodeId>/drain` | POST | Marks a registered node as `Draining` after checking the secret. |

When a secret is configured, protected requests must provide it in the `x-registration-secret` header.

Register nodes directly when embedding the scaffold:

```d
NodeInfo info;
info.id = "node-1";
info.uri = "http://127.0.0.1:5555";
info.availability = Availability.Up;

hub.registerNode(info);
GridStatus status = hub.status;
```

`status.ready` currently means that at least one node is registered. It does not inspect each node's availability or verify that a node can accept a session.

## Node

`Node.start` creates one slot stereotype per browser and registers the node routes:

```d
import selenium.browser.chrome : Chrome;
import selenium.browser.firefox : Firefox;
import selenium.grid;

Node node = Node.start(
    [new Chrome(), new Firefox()],
    "http://127.0.0.1:4444",
    5555,
    "my-secret"
);
scope (exit) node.stop();
```

| Parameter | Purpose |
| --- | --- |
| `slotBrowsers` | Browser capabilities used to create one advertised stereotype per slot. |
| `hubAddress` | Hub URL stored on the node. registration is not performed automatically. |
| `port` | Port included in the advertised loopback address. Defaults to `5555`. |
| `secret` | Secret checked by protected routes, or `null` to accept those requests without a secret. |

| Route | Method | Current behavior |
| --- | --- | --- |
| `/status` | GET | Returns the node's in-memory slots and metadata. |
| `/se/grid/node/drain` | POST | Checks the secret and returns success. draining state is not yet persisted. |
| `/se/grid/node/owner/<sessionId>` | GET | Reports whether an in-memory slot contains the session ID. |
| `/se/grid/node/session/<sessionId>` | DELETE | Clears a matching session ID from an in-memory slot. |

`Node.start` does not populate `node.bridges`. WebDriver process startup remains part of the future live-serving layer.

## Routing In Process

`Router.dispatch` can exercise routes without sockets. Requests and responses use the package's lightweight HTTP models:

```d
Request request;
request.method = "GET";
request.path = "/status";

Response response = hub.router.dispatch(request);
assert(response.status == 200);
```

Path parameters such as `<nodeId>` and `<sessionId>` are added to `request.params` before a handler is called.

## Models

All Grid models serialize with `toJSON` and parse with `fromJSON` where provided.

| Type | Purpose |
| --- | --- |
| `GridStatus` | Readiness flag, message, and registered nodes. |
| `NodeInfo` | Node ID, URI, session capacity, availability, OS data, and slots. |
| `Slot` | Slot ID, capability stereotype, and optional session ID. |
| `Stereotype` | Dynamic browser capability object advertised by a slot. |
| `SessionInfo` | Session ID, owning node ID, and negotiated capabilities. |
| `Availability` | `Up`, `Down`, or `Draining`. serialized as lowercase strings. |

`GridStatus.fromJSON`, `NodeInfo.fromJSON`, and `SessionInfo.fromJSON` accept either a bare object or a WebDriver-style `{ "value": ... }` envelope.

## Connecting to an Existing Grid

The WebDriver client can connect to a separately running Selenium Grid or remote WebDriver endpoint:

```d
import selenium;

Driver driver = Driver.connect("http://grid.example.com:4444", new Chrome());
scope (exit) driver.stop();

driver.go("https://example.com");
```

This uses `selenium:webdriver` and does not turn the local `Hub` scaffold into a server. `bridge.status()` returns a parsed `JSONValue`. when the remote endpoint has a compatible Grid status shape, parse it with:

```d
import selenium.grid : GridStatus;

GridStatus status = GridStatus.fromJSON(driver.bridge.status());
```
