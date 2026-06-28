# Driver (WebDriver)

A `Driver` is a handle to a single WebDriver session. It wraps the session id and the bridge that hosts it, and exposes the commands you use to drive the browser.

For the official Selenium documentation on drivers, see https://www.selenium.dev/documentation/webdriver/drivers/.

## Starting a session

| Overload | Purpose |
| --- | --- |
| `Driver.start()` | Starts a session with a generic browser, letting the first driver on `PATH` win. |
| `Driver.start(Browser alwaysMatch, Browser[] firstMatch, Logger logger)` | Resolves the binary, spawns a bridge, and starts a session. |
| `Driver.start(Bridge bridge, Browser alwaysMatch, Browser[] firstMatch, Logger logger)` | Starts a session on an existing bridge. |
| `Driver.connect(string address, Browser alwaysMatch, Browser[] firstMatch, Logger logger)` | Connects to a remote server or grid and starts a session. |

```d
import selenium;
import selenium.browser.chrome : Chrome;

Driver driver = Driver.start(new Chrome());
scope (exit) driver.stop();
```

In Ruby:

```ruby
driver = Selenium::WebDriver.for :chrome
```

`Driver.start` combines `Selenium::WebDriver.for` and `Selenium::WebDriver::Service` into one call. The bridge is spawned and the session is created in a single step.

### Remote connections

`Driver.connect` attaches to an already running WebDriver server or grid hub. The backing `Bridge` has a capacity of 1, so only this driver's session may use it. The bridge does not own a process, so `stop` will not kill the remote server.

```d
Driver driver = Driver.connect("http://grid.example.com:4444", new Chrome());
scope (exit) driver.stop();
```

In Ruby:

```ruby
driver = Selenium::WebDriver.for :remote, url: 'http://grid.example.com:4444', capabilities: options
```

## Stopping a session

`stop` ends only this driver's session and leaves the bridge alive for any others. Unlike `Bridge`, a `Driver` does not destruct automatically.

```d
driver.stop();
```

In Ruby this is `driver.quit`. The naming differs because `Driver` does not own the bridge, so "stop" refers to the session, not the process.

## Navigation

| Call | Action |
| --- | --- |
| `driver.go(url)` | Navigate to a URL. |
| `driver.back()` | Navigate back one entry in history. |
| `driver.forward()` | Navigate forward one entry in history. |
| `driver.refresh()` | Reload the current document. |
| `driver.url` | Current document URL. |
| `driver.title` | Current document title. |
| `driver.source` | Serialized page source. |
| `driver.screenshot` | Base64 PNG of the viewport. |

```d
driver.go("https://example.com");
writeln(driver.title);
driver.back();
```

In Ruby: `driver.get`, `driver.title`, `driver.navigate.back`, `driver.navigate.forward`, `driver.navigate.refresh`. The D version uses `go` instead of `get` to avoid confusion with D's `get` property convention.

## Finding elements

| Call | Action |
| --- | --- |
| `driver.find(By by)` | First element matching the locator. Throws `NoSuchElementException` if none match. |
| `driver.findAll(By by)` | Every element matching the locator, or an empty array. |

```d
Element button = driver.find(By.css("#submit"));
Element[] items = driver.findAll(By.xpath("//li[@class='item']"));
```

In Ruby: `driver.find_element(css: '#submit')` and `driver.find_elements(xpath: "//li[@class='item']")`.

## Script execution

`execute` runs a synchronous script in the page and returns its typed result. When `T` is `Element` or `Element[]`, the returned references are wrapped into handles.

```d
int sum = driver.execute!int("return arguments[0] + arguments[1];", JSONValue([2, 3]));
Element created = driver.execute!Element("return document.querySelector('#foo');");
```

In Ruby: `driver.execute_script('return arguments[0] + arguments[1];', 2, 3)`. The D version requires a JSONValue for arguments and a template parameter for the return type, since D does not have Ruby's dynamic dispatch.

## Windows and tabs

| Call | Action |
| --- | --- |
| `driver.window.handle` | Handle of the current window. |
| `driver.window.handles` | Handles of all open windows. |
| `driver.window.size` | Size of the current window. |
| `driver.window.close()` | Close the current window. |
| `driver.window.maximize()` | Maximize the current window. |
| `driver.window.minimize()` | Minimize the current window. |
| `driver.window.fullscreen()` | Fullscreen the current window. |
| `driver.window.resize(Size)` | Resize the current window. |
| `driver.window.switchTo(handle)` | Switch focus to a window by handle. |
| `driver.window.open(type)` | Open a new window or tab and return its handle. |

```d
string tab = driver.window.open("tab");
driver.window.switchTo(tab);
```

In Ruby: `driver.window_handles`, `driver.switch_to.window(handle)`, `driver.manage.window.maximize`. The D version groups these under the `window` alias for discoverability.

## Frames

| Call | Action |
| --- | --- |
| `driver.frame.switchTo()` | Switch to the top-level browsing context. |
| `driver.frame.switchTo(long id)` | Switch to the frame at the given index. |
| `driver.frame.switchTo(Element element)` | Switch to the frame identified by the element. |
| `driver.frame.switchToParent()` | Switch to the parent of the current frame. |

```d
driver.frame.switchTo(0);
// ... interact with frame contents ...
driver.frame.switchTo();
```

In Ruby: `driver.switch_to.frame(0)` and `driver.switch_to.default_content`. The D version groups these under the `frame` alias.

## Roots

A `Root` is a searchable context within the DOM. The primary document, iframes, and shadow roots are all roots. `driver.root` returns the primary document, and `driver.roots` returns all searchable roots in the current browsing context.

```d
Root doc = driver.root;
Element[] headings = doc.findAll(By.tagName("h1"));

Root[] all = driver.roots;
foreach (root; all)
{
    if (root.type == RootType.Shadow)
    {
        Element[] shadowButtons = root.findAll(By.css("button"));
    }
}
```

Shadow root search uses the W3C shadow root endpoints directly, so no frame switching is needed. Embedded root search temporarily switches to the iframe and restores the parent frame afterwards.

## Cookies

Cookies are accessed through the `cookies` UFCS helper, which returns a `CookieStore` scoped to the driver's session.

| Call | Action |
| --- | --- |
| `driver.cookies.all()` | Every cookie visible to the current document. |
| `driver.cookies.find(name)` | A single cookie by name. |
| `driver.cookies.add(Cookie)` | Add or update a cookie. |
| `driver.cookies.remove(name)` | Delete a single cookie by name. |
| `driver.cookies.clear()` | Delete every cookie for the current document. |

```d
driver.cookies.add(Cookie("session", "abc123"));
Cookie[] all = driver.cookies.all();
driver.cookies.clear();
```

In Ruby: `driver.manage.add_cookie(name: 'session', value: 'abc123')`, `driver.manage.all_cookies`, `driver.manage.delete_cookie('session')`, `driver.manage.delete_all_cookies`.

## Logging

The `Logger` on a driver aggregates client-side, driver-process, and remote logging for the session. Per-browser logging preferences are folded upward into one logger when a session starts.

| Call | Action |
| --- | --- |
| `driver.logger.types()` | Log types the driver exposes via `/log/types`. |
| `driver.logger.fetch(type)` | Fetch and clear pending remote logs of a type. |
| `driver.logger.drain(LogType)` | Fetch, retain, and forward entries to the sink. |
| `driver.logger.entries` | Remote log entries drained so far. |

```d
import selenium.driver.logger : LogType;

LogEntry[] browserLogs = driver.logger.drain(LogType.Browser);
foreach (entry; browserLogs)
    writeln(entry.level, ": ", entry.message);
```