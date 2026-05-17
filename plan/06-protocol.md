# 06 — WebDriver Protocol Modernization

## JsonWireProtocol vs W3C WebDriver

The inherited code was written for the old Selenium **JSON Wire Protocol**. Modern browsers and WebDriver servers (Chromedriver, Geckodriver) implement the **W3C WebDriver** standard.

### Response Format Differences

| Aspect | JsonWireProtocol | W3C WebDriver |
|--------|-----------------|---------------|
| Success envelope | `{ status: 0, sessionId: "...", value: ... }` | `{ value: ... }` |
| Error envelope | `{ status: 7, value: { message: "..." } }` | `{ value: { error: "no such element", message: "..." } }` |
| Element ID key | `ELEMENT` | `element-6066-11e4-a52e-4f735466cecf` |
| Session creation | `POST /session` with `desiredCapabilities`/`requiredCapabilities` | `POST /session` with `capabilities.alwaysMatch` |

### Endpoint Changes

| JsonWireProtocol | W3C WebDriver | Status |
|------------------|---------------|--------|
| `GET /window_handle` | `GET /window` | Changed |
| `GET /window_handles` | `GET /window/handles` | Changed |
| `POST /window/size` | `POST /window/rect` | Changed |
| `POST /timeouts/implicit_wait` | `POST /timeouts` with body | Changed |
| `POST /moveto` | Removed | Deprecated |
| `POST /click` (mouse) | Removed | Deprecated |
| `POST /buttondown` | Removed | Deprecated |
| `POST /touch/*` | Removed | Deprecated |
| `GET /local_storage` | Removed | Deprecated |
| `GET /session_storage` | Removed | Deprecated |
| `GET /ime/*` | Removed | Deprecated |
| `GET /orientation` | Removed | Deprecated |
| `GET /location` | Removed | Deprecated |
| `GET /application_cache/status` | Removed | Deprecated |

## W3C Element ID Abstraction

The new `WebElement` struct must handle both protocols:

```d
struct WebElement
{
    string id;

    static WebElement fromResponse(JSONValue response)
    {
        WebElement ret;

        enum W3C_KEY = "element-6066-11e4-a52e-4f735466cecf";

        if (auto p = W3C_KEY in response)
            ret.id = p.str;
        else if (auto p = "ELEMENT" in response)
            ret.id = p.str;

        return ret;
    }
}
```

The `protocol/response.d` module parses server responses and constructs `WebElement` instances using this abstraction. Callers never see the raw key.

## W3C Error Mapping

W3C WebDriver uses string error codes instead of numeric status codes. The response parser maps them to our exception hierarchy:

| W3C `error` | Exception |
|-------------|-----------|
| `no such element` | `NoSuchElementError` |
| `stale element reference` | `StaleElementReferenceError` |
| `invalid element state` | `InvalidElementStateError` |
| `timeout` | `WebDriverTimeoutError` |
| `session not created` | `WebDriverConnectionError` |
| `unknown error` | `WebDriverError` |

## Capabilities Serialization

W3C WebDriver expects a different session creation payload:

```d
JSONValue toW3CCapabilities(Capabilities desired)
{
    JSONValue ret = JSONValue.emptyObject;
    ret["capabilities"] = JSONValue.emptyObject;
    ret["capabilities"]["alwaysMatch"] = desired.toJSONValue();
    return ret;
}
```

During the migration, we should support both formats by detecting the server's response shape:
- If `sessionId` is at the top level, the server speaks JsonWireProtocol.
- If `sessionId` is inside `value.sessionId`, the server speaks W3C.

The current code already has a partial compatibility patch for this. The overhaul should make the detection explicit and centralize it in `protocol/response.d`.

## Removed Endpoints

The following endpoints from the old `SeleniumApi` are **not** ported to the new `Client`:

- `imeAvailableEngines()`
- `imeActiveEngine()`
- `imeActivated()`
- `imeDeactivate()`
- `imeActivate()`
- `orientation()` / `setOrientation()`
- `moveTo()` / `click(MouseButton)` / `buttonDown()` / `buttonUp()` / `doubleClick()`
- `touchClick()` / `touchDown()` / `touchUp()` / `touchMove()` / `touchScroll()` / `touchFlick()`
- `localStorage()` / `setLocalStorage()` / `deleteLocalStorage()` / `localStorageSize()`
- `sessionStorage()` / `setSessionStorage()` / `deleteSessionStorage()` / `sessionStorageSize()`
- `applicationCacheStatus()`
- `geoLocation()` / `setGeoLocation()`

If any of these are still needed for legacy Selenium Grid setups, they can be added to a `selenium/protocol/legacy.d` module that extends `Client`.
