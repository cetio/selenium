# Bridge

A `Bridge` represents one WebDriver server. It owns the process when started locally or stores the address of a remote server. Multiple `Driver` instances can share a bridge, with each driver bound to a separate session.

For upstream information about local driver services, see the [official Selenium documentation](https://www.selenium.dev/documentation/webdriver/drivers/service/).

## Construction

A bridge's session `capacity` is fixed at construction. Zero means unlimited:

```d
Bridge bridge = new Bridge(0);
```

A directly constructed bridge has no address until the caller sets `bridge.address`. Most callers use `Bridge.start` for a local process or `Driver.connect` for a remote endpoint.

## Starting a Local WebDriver

`Bridge.start` finds a free loopback port, launches the executable with `--port=<port>`, appends any supplied arguments, and waits up to five seconds for `/status` to return HTTP 200.

```d
import selenium;

Bridge bridge = Bridge.start("chromedriver", ["--log-level=OFF"], 2);
scope (exit) bridge.stop();
```

| Parameter | Purpose |
| --- | --- |
| `binary` | WebDriver executable path. |
| `args` | Additional process arguments. Defaults to `null`. |
| `capacity` | Maximum concurrent sessions, or zero for unlimited. Defaults to zero. |

The bridge owns the spawned process. `stop` kills it and clears local session state. The destructor also calls `stop`, but explicit cleanup is recommended.

## Remote Connections

`Driver.connect` constructs a bridge with capacity one, assigns the supplied address, and creates a session. The bridge does not own a process, so stopping it cannot terminate the remote server.

```d
import selenium;

Driver driver = Driver.connect("http://grid.example.com:4444", new Chrome());
scope (exit) driver.stop();
```

To share a caller-managed remote bridge across sessions, construct and configure it directly, then use the `Driver.start(Bridge, ...)` overload.

## Sharing a Local Bridge

```d
import selenium;

Chrome browser = new Chrome();
Bridge bridge = Bridge.start(browser.resolveBinary(), null, 2);
scope (exit) bridge.stop();

Driver first = Driver.start(bridge, browser, null);
scope (exit) first.stop();

Driver second = Driver.start(bridge, new Chrome(), null);
scope (exit) second.stop();
```

Creating a session beyond a positive capacity throws `WebDriverConnectionException` before a request is sent.

## Session Management

| Member | Purpose |
| --- | --- |
| `createSession(payload)` | Creates a session and returns its ID. |
| `closeSession(id)` | Requests session deletion and removes local state even if deletion fails. |
| `sessions` | Negotiated `Browser` capabilities keyed by session ID. |
| `stop()` | Kills an owned process and clears all local sessions. |

## Status

`status()` requests the server's `/status` endpoint and returns the parsed response as `JSONValue`, including its WebDriver `value` envelope.

```d
import std.json : JSONValue;

JSONValue response = bridge.status();
```

A caller connected to a compatible Grid endpoint can pass that value to `GridStatus.fromJSON`.

## Low-Level Session Commands

`Driver`, `Element`, and `Root` build on the bridge's public HTTP helpers. Paths are relative to `/session/<id>`.

| Method | Request body |
| --- | --- |
| `get!T(id, path)` | None. |
| `post!T(id, path)` | Empty JSON object. |
| `post!T(id, path, JSONValue data)` | JSON. |
| `post!T(id, path, string data, string contentType)` | Raw text with optional content type. |
| `put!T(id, path, data)` | JSON. |
| `patch!T(id, path, data)` | JSON. |
| `del!T(id, path)` | None. |

`T` defaults to `JSONValue`, which preserves the complete response envelope. Other return types are deserialized from the envelope's `value` member.

```d
string title = bridge.get!string(sessionId, "/title");
JSONValue response = bridge.post(sessionId, "/refresh");
```

HTTP error responses are mapped to the exception types in `selenium.exception`.

## Reference Parsing

The static helpers below accept a bare value or a WebDriver response envelope:

| Method | Purpose |
| --- | --- |
| `parseElementId(json)` | Extract one W3C or legacy `ELEMENT` reference. |
| `parseElementIds(json)` | Extract element references from an array in order. |
| `parseShadowId(json)` | Extract one W3C shadow-root reference. |
| `parseShadowIds(json)` | Extract shadow-root references from an array in order. |
| `unwrapAndParse!T(json)` | Unwrap `value` and deserialize it as `T`. |
