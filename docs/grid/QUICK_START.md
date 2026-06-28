# Grid Quick Start

The `grid` package is the Selenium Grid server side of the SDK. It is a standalone top-level package (`import grid;`) separate from the `selenium` WebDriver client, so the two can evolve independently. A grid client surface is growing inside `selenium.driver` and `selenium.bridge`: `Driver.connect` attaches to a remote server or grid hub and starts a session, and `Bridge.status` fetches the `/status` payload as raw JSON, which can be parsed into `GridStatus` without coupling `Bridge` to grid types.

The grid server is a scaffold. The data models, hub and node structure, and routing are in place, but a live HTTP server loop is not yet wired. This guide covers what is available today. For the WebDriver client see [../selenium/QUICK_START.md](../selenium/QUICK_START.md), for the testing workflow see [../../TESTING.md](../../TESTING.md), and for contribution guidelines see [../../CONTRIBUTING.md](../../CONTRIBUTING.md).

## Design

The Hub and Node mirror the existing `Bridge` and `Driver` relationship, but across processes over HTTP instead of shared memory. A `Node` composes one or more `selenium.bridge.Bridge` instances and reuses all the existing WebDriver lifecycle, timeout, and session machinery. A `Hub` owns the node registry and session ownership map, builds grid status, and routes new-session requests to a matching node. The Hub does not host WebDriver sessions itself. It forwards them.

| Selenium | Grid | Role |
| --- | --- | --- |
| `Bridge` | `Node` | Owns WebDriver capacity and hosts sessions. |
| `Driver` | `Hub` | A handle that coordinates and routes. |

## Models

The models live in `grid.server.model` and map to the Selenium Grid wire envelope. Dynamic parts such as slot capabilities, OS info, and negotiated session capabilities are kept as `JSONValue` rather than typed mirrors, since they vary per browser and vendor extension.

| Type | Wire shape |
| --- | --- |
| `Stereotype` | A slot's advertised capability object. |
| `Slot` | `{ id, stereotype, session }`, with `occupied` derived from the session id. |
| `NodeInfo` | `{ id, uri, maxSessions, availability, osInfo, slots }`. |
| `GridStatus` | `{ ready, message, nodes }`, the `/status` payload. |
| `SessionInfo` | `{ id, nodeId, capabilities }`, a hub-side session record. |

Each model has `toJSON` (bare object) and a static `fromJSON` that accepts either a bare object or a `{"value": ...}` envelope. The W3C envelope wrapping is done by the route handlers, not the models, so the models stay reusable.

```d
import grid;

NodeInfo node;
node.id = "node-1";
node.uri = "http://127.0.0.1:5555";
node.maxSessions = 2;
node.availability = Availability.Up;

GridStatus status;
status.ready = true;
status.nodes ~= node;

JSONValue wire = status.toJSON();
GridStatus roundTrip = GridStatus.fromJSON(wire);
```

`Availability` is an enum mirroring the wire values: `Up`, `Down`, `Draining`.

## Hub

A `Hub` is the grid entry point. It owns a `Router` populated with every grid endpoint and tracks registered nodes and active sessions. You usually do not touch the router directly. Reach for `Hub.start` when you want to coordinate multiple nodes.

| Member | Purpose |
| --- | --- |
| `Hub.start(port, secret)` | Configure a hub on a port and register routes. |
| `status()` | Build the current `GridStatus` from the node registry. |
| `registerNode(node)` | Add or refresh a node in the registry. |
| `removeNode(nodeId)` | Drop a node from the registry. |
| `nodes` | Registered nodes keyed by id. |
| `sessions` | Active sessions keyed by id. |
| `router` | The route table. Dispatch requests through it. |
| `stop()` | Release the registry and route table. |

```d
import grid;

Hub hub = Hub.start(4444, "s3cr3t");
scope (exit) hub.stop();

hub.registerNode(node);
GridStatus status = hub.status();
```

## Node

A `Node` hosts WebDriver slots and serves node-level endpoints. Each slot is built from a `Browser` stereotype, so the routing surface can be exercised without live drivers.

| Member | Purpose |
| --- | --- |
| `Node.start(slotBrowsers, hubAddress, port, secret)` | Configure a node with one slot per browser. |
| `status()` | Build the local `NodeInfo` from the slot table. |
| `slots` | The advertised slots, each with a stereotype and optional session. |
| `bridges` | The `selenium.bridge.Bridge` instances backing each slot. Populated when live serving begins. |
| `router` | The route table. Dispatch requests through it. |
| `stop()` | Stop every bridge and release state. |

```d
import grid;
import selenium.browser.chrome : Chrome;

Chrome chrome = new Chrome();
Node node = Node.start([chrome]);
scope (exit) node.stop();

NodeInfo status = node.status();
```

## Routing

The `Router` is the seam between endpoint logic and transport. A future socket accept loop parses incoming bytes into a `Request`, hands it to `Router.dispatch`, and writes the returned `Response`. Every endpoint is registered as a handler, so the full surface is testable without sockets.

| Endpoint | Method | Handler |
| --- | --- | --- |
| `/status` | GET | Grid or node status. |
| `/session/<sessionId>` | DELETE | End a session. |
| `/se/grid/distributor/node/<nodeId>` | DELETE | Remove a node from the hub. |
| `/se/grid/distributor/node/<nodeId>/drain` | POST | Mark a node draining. |
| `/se/grid/node/drain` | POST | Drain the local node. |
| `/se/grid/node/owner/<sessionId>` | GET | Whether the node owns a session. |
| `/se/grid/node/session/<sessionId>` | DELETE | End a session on the node. |

Secured distributor and node endpoints require an `X-REGISTRATION-SECRET` header matching the configured secret. Open grids with no secret accept any request.

```d
import grid;

Hub hub = Hub.start();
Request request = Request("GET", "/status");
Response response = hub.router.dispatch(request);
```

`Response` helpers cover the common shapes: `ok(json)`, `okValue(value)` (wraps in the W3C `{"value": ...}` envelope), `withJson(status, reason, json)`, `noContent()`, and `error(status, reason, errorCode, message)` (the W3C error envelope).
