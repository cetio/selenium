# Bridge (WebDriver)

A `Bridge` is the low-level connection to a WebDriver server. It owns the server process when spawned locally, or holds the address of a remote server. Multiple `Driver` instances can share a single bridge, each bound to a different session on the same server.

For the official Selenium documentation on driver services, see https://www.selenium.dev/documentation/webdriver/drivers/service/.

## Construction

`capacity` is `const` and fixed at construction. A capacity of 0 means unlimited.

```d
Bridge bridge = new Bridge(0);
```

You usually do not call the constructor directly. `Bridge.start` or `Driver.connect` create one for you.

## Spawning a local driver

`Bridge.start` spawns a WebDriver binary on a free port and waits for it to become ready.

```d
Bridge bridge = Bridge.start("chromedriver", null, 2);
scope (exit) bridge.stop();
```

| Parameter | Purpose |
| --- | --- |
| `binary` | Path to the driver executable. |
| `args` | Extra command-line arguments forwarded to the executable. |
| `capacity` | Maximum concurrent sessions, or 0 for unlimited. |

The bridge owns the spawned process. `stop` kills it and clears all session state. The destructor calls `stop` automatically, but calling it explicitly is good practice when sharing a bridge across scopes.

In Ruby, this role is filled by `Selenium::WebDriver::Service`:

```ruby
service = Selenium::WebDriver::Service.chrome(path: 'chromedriver', args: ['--port=9515'])
driver = Selenium::WebDriver.for :chrome, service: service
```

The D version folds the service into the bridge, so one object owns both the process and the session connection.

## Remote connections

A remote bridge is created through `Driver.connect`, which sets `capacity` to 1 so only the connecting session may use it. The bridge does not own a process, so `stop` will not kill the remote server.

```d
Driver driver = Driver.connect("http://grid.example.com:4444", new Chrome());
// driver.bridge.address == "http://grid.example.com:4444"
// driver.bridge.capacity == 1
```

## Session management

| Member | Purpose |
| --- | --- |
| `createSession(payload)` | Creates a new session and returns its id. Throws `WebDriverConnectionException` if `capacity` is reached. |
| `closeSession(id)` | Ends a single session and removes it from `sessions`. Errors from the server are ignored so a dead session is still dropped locally. |
| `sessions` | Active sessions keyed by id, mapped to their negotiated `Browser`. |
| `stop()` | Kills a spawned process and clears all session state. Idempotent. |

## Status

`status()` fetches `GET /status` from the server and returns the raw parsed JSON. Any WebDriver server answers `/status` with a `{"value": ...}` envelope. For a grid hub the value contains node and slot information; for a standalone driver it contains readiness and a message.

```d
import std.json : JSONValue;
JSONValue raw = bridge.status();
```

The raw JSON is returned so the caller can parse it into `selenium.grid.server.model.GridStatus` or inspect it directly, keeping `Bridge` decoupled from grid types.

## Request dispatch

`Bridge` exposes a generic `request` method that the `Driver` and `Element` classes build on. You should not need to call it directly, but it is public:

```d
JSONValue resp = bridge.request(sessionId, HTTP.Method.get, "/title");
```

| Overload | Purpose |
| --- | --- |
| `request(id, method, path)` | Parameterless command. POST is redirected to send an empty JSON body for W3C compliance. |
| `request(id, method, path, data)` | Command with a request body, serialized to JSON. |

The template parameter `T` controls the return type. `JSONValue` (the default) returns the raw response. Other types are deserialized from the W3C `value` envelope via `unwrapAndParse!T`.

## Element reference parsing

`Bridge` provides static helpers for extracting element and shadow root references from response JSON. These are used internally by `Element` and `Root`, and are public for custom command implementations.

| Method | Purpose |
| --- | --- |
| `parseElementId(json)` | Extracts a single W3C element reference, accepting both the W3C key and the legacy `ELEMENT` key. |
| `parseElementIds(json)` | Extracts every element reference from an array response. |
| `parseShadowId(json)` | Extracts a single shadow root reference. |
| `parseShadowIds(json)` | Extracts every shadow root reference from an array response. |