# Driver

A `Driver` is a handle to one WebDriver session. It stores the session ID, negotiated browser capabilities, logger, and bridge used for commands.

Unlike `Bridge`, `Driver` has no destructor. Call `stop()` to end its session. This leaves the bridge and any other sessions on it alive.

## Starting and Connecting

| Overload | Purpose |
| --- | --- |
| `Driver.start()` | Starts a generic session using the first known WebDriver executable on `PATH`. |
| `Driver.start(Browser alwaysMatch, Browser[] firstMatch = null, Logger logger = null)` | Starts a local WebDriver process and creates a session. |
| `Driver.start(Bridge bridge, Browser alwaysMatch, Browser[] firstMatch, Logger logger = null)` | Creates a session on an existing bridge. |
| `Driver.connect(string address, Browser alwaysMatch, Browser[] firstMatch = null, Logger logger = null)` | Creates a session on a remote WebDriver endpoint. |

```d
import selenium;

Driver driver = Driver.start(new Chrome());
scope (exit) driver.stop();
```

`Driver.connect` creates a non-owning bridge with capacity one. It does not stop the remote service:

```d
Driver driver = Driver.connect("http://grid.example.com:4444", new Chrome());
scope (exit) driver.stop();
```

## Navigation and Document State

| Member | Action |
| --- | --- |
| `go(url)` | Navigate to a URL. |
| `back()` | Move back one history entry. |
| `forward()` | Move forward one history entry. |
| `refresh()` | Reload the current document. |
| `url` | Current document URL. |
| `title` | Current document title. |
| `source` | Serialized page source. |
| `screenshot` | Base64 PNG of the viewport. |

```d
driver.go("https://example.com");
writeln(driver.title);
driver.refresh();
```

## Finding Elements

`find` returns the first match and throws `NoSuchElementException` when no element matches. `findAll` returns all matches in document order or an empty array. `activeElement` returns the element that currently has focus.

```d
Element button = driver.find(By.css("#submit"));
Element[] items = driver.findAll(By.xpath("//li[@class='item']"));
Element focused = driver.activeElement;
```

See [Elements](ELEMENTS.md) for locators, element state, interaction, descendant search, and shadow roots.

## Script Execution

`execute!T` runs a synchronous script. Its optional arguments must be a JSON array. Results are deserialized as `T`. `Element` and `Element[]` results become handles for this driver.

```d
import std.json : JSONValue;

int sum = driver.execute!int(
    "return arguments[0] + arguments[1];",
    JSONValue([JSONValue(2), JSONValue(3)])
);
Element selected = driver.execute!Element("return document.querySelector('#selected');");
```

Asynchronous script execution is not currently implemented.

## Windows and Tabs

Window commands are grouped under `driver.window`:

| Member | Action |
| --- | --- |
| `handle` | Current window handle. |
| `handles` | All window handles. |
| `size` | Current window width and height. |
| `open(type = "tab")` | Open a tab or window and return its handle. |
| `switchTo(handle)` | Focus a window. |
| `close()` | Close the current window. |
| `resize(Size)` | Resize the current window. |
| `maximize()` | Maximize the current window. |
| `minimize()` | Minimize the current window. |
| `fullscreen()` | Enter fullscreen mode. |

```d
string original = driver.window.handle;
string opened = driver.window.open("tab");
driver.window.switchTo(opened);
driver.window.close();
driver.window.switchTo(original);
```

## Frames

Frame commands are grouped under `driver.frame`:

| Member | Action |
| --- | --- |
| `switchTo()` | Switch to the top-level browsing context. |
| `switchTo(long index)` | Switch to a frame by index. |
| `switchTo(Element element)` | Switch to the frame represented by an element. |
| `switchToParent()` | Switch to the parent browsing context. |

```d
driver.frame.switchTo(0);
// Interact with frame contents.
driver.frame.switchToParent();
```

## Roots

A `Root` is a searchable primary document, iframe, or shadow root. `driver.root` returns the primary root. `driver.roots` executes JavaScript to discover the primary document, top-level iframes, and open shadow roots in the current browsing context.

```d
Root documentRoot = driver.root;
Element[] headings = documentRoot.findAll(By.tagName("h1"));

foreach (root; driver.roots)
{
    if (root.type == RootType.Shadow)
        root.findAll(By.css("button"));
}
```

Shadow-root searches use W3C shadow endpoints. Searching an embedded root switches the driver into that iframe and leaves it there. Call `driver.frame.switchToParent()` or `driver.frame.switchTo()` when finished.

`Root.state` is a `RootState` bitmask describing document readiness and whether a shadow root is open or closed.

## Cookies

The UFCS property `driver.cookies` creates a `CookieStore` scoped to the session:

| Member | Action |
| --- | --- |
| `all()` | Read every cookie visible to the current document. |
| `find(name)` | Read one cookie. |
| `add(cookie)` | Add or update a cookie. |
| `remove(name)` | Delete one cookie. |
| `clear()` | Delete all cookies visible to the current document. |

```d
driver.cookies.add(Cookie("session", "abc123"));
Cookie[] cookies = driver.cookies.all();
driver.cookies.remove("session");
```

`Cookie` supports path, domain, secure, HTTP-only, expiry, and SameSite fields in addition to name and value.

## Logging

A driver's `Logger` combines driver-process options, Chromium logging capabilities, and legacy remote log retrieval. Remote `/log` commands are vendor extensions and may not be supported by every browser.

| Member | Purpose |
| --- | --- |
| `levels` | Requested remote levels by log type. |
| `path`, `driverLevel`, `append`, `readableTimestamp`, `silent` | Local WebDriver process logging options. |
| `types()` | Query remote log types. |
| `fetch(type)` | Fetch and clear pending remote entries. |
| `drain(type)` | Fetch entries and retain them in `entries`. |
| `entries` | Entries retained by previous drains. |

```d
import selenium.driver.logger : LogEntry, LogType;

LogEntry[] browserLogs = driver.logger.drain(LogType.Browser);
foreach (entry; browserLogs)
    writeln(entry.level, ": ", entry.message);
```

Chrome and Edge serialize their per-type logging preferences as `goog:loggingPrefs` and merge them into the session logger when the session starts.
