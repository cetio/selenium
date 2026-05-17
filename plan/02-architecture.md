# 02 — Target Architecture

## Design Principles

1. **Zero-Config Driver Start** — `Driver.start()` auto-detects the best available driver (Chrome highest priority), finds a free port, launches the server, and creates a session. A single call returns a fully operational browser controller.

2. **Unified Driver / Session Interface** — Following Ruby's `Selenium::WebDriver::Driver`, the `Driver` class is the single object users interact with. It manages the browser process AND exposes all session-level operations. No separate `Session` object is passed around.

3. **SearchContext Mixin Pattern** — Both `Driver` and `Element` expose `findOne` / `findMany`. Element lookups are a first-class concern of whichever context you have in hand.

4. **Comptime Locator Strategies** — `driver.findOne!"xpath"("//div")` is the primary API. This avoids `ElementLocator` struct construction at call sites and enables compile-time validation.

5. **Modular Decomposition** — Each concern lives in its own module. No file exceeds ~250 lines.

## Directory Structure

```
source/selenium/
  package.d                    # Re-export public API
  errors.d                     # Exception hierarchy
  types.d                      # Capabilities, Cookie, Size, Position, enums
  locator.d                    # ElementLocator + runtime factory functions
  protocol/
    package.d                  # Re-export protocol components
    client.d                   # HTTP client (raw GET/POST/DELETE)
    response.d                 # W3C response parsing, error mapping
  driver.d                     # Unified Driver: process + session + search context
  element.d                    # Element wrapper with scoped search context
  page.d                       # Lightweight Page base class
source/tests/
  behaviors.d                  # Static unit tests
  dynamic.d                    # Integration tests
```

## Module Responsibilities

| Module | Responsibility |
|--------|--------------|
| `selenium.errors` | `WebDriverError` hierarchy with specific error types using `mixin basicExceptionCtors` |
| `selenium.types` | `Capabilities`, `Cookie`, `Size`, `Position`, `Browser`, `Platform`, `LocatorStrategy`, etc. |
| `selenium.locator` | `ElementLocator` struct and runtime factory functions (`byId`, `byCss`, etc.) |
| `selenium.protocol.client` | Raw HTTP client: `get!T`, `post`, `post!T`, `delete_`. Handles `session/` prefix, JSON via `conductor` |
| `selenium.protocol.response` | Parse W3C WebDriver responses, map `error` field to exception types |
| `selenium.driver` | **Unified Driver class**: process lifecycle (`start`, `stop`), session operations (`url`, `back`, `findOne`) |
| `selenium.element` | `Element` class: properties (`text`, `click`, `sendKeys`) AND scoped search (`findOne`, `findMany`) |
| `selenium.page` | `Page` base class with `isPresent()` and `waitFor()` helpers |

## Ruby API Pattern Applied

Ruby's `Selenium::WebDriver::Driver` is the single entry point:

```ruby
driver = Selenium::WebDriver.for :chrome
driver.get "http://example.com"
element = driver.find_element(:id, "foo")
element.click
driver.quit
```

Our D equivalent:

```d
Driver driver = Driver.start(); // Auto-detects Chrome, launches, creates session
driver.url("http://example.com");
Element element = driver.findOne!"id"("foo");
element.click;
driver.quit;
```

Key observations from Ruby:
- `Driver` includes `SearchContext` (mixin) — `find_element` is a method on `Driver` itself
- `Element` also includes `SearchContext` — scoped element search works the same way
- `driver.navigate.to(url)` exists, but `driver.get(url)` is the common shortcut
- `driver.manage` groups cookies/timeouts/window, but direct accessors are also common

Our D API merges `manage` and direct accessors into flat methods on `Driver`.

## Comptime Locator Strategy Map

A compile-time template maps string literals to `LocatorStrategy` enum values:

```d
template LocatorOf(string strategy)
{
    static if (strategy == "class")
        enum LocatorStrategy LocatorOf = LocatorStrategy.ClassName;
    else static if (strategy == "css")
        enum LocatorStrategy LocatorOf = LocatorStrategy.CssSelector;
    else static if (strategy == "id")
        enum LocatorStrategy LocatorOf = LocatorStrategy.Id;
    else static if (strategy == "name")
        enum LocatorStrategy LocatorOf = LocatorStrategy.Name;
    else static if (strategy == "linkText")
        enum LocatorStrategy LocatorOf = LocatorStrategy.LinkText;
    else static if (strategy == "partialLinkText")
        enum LocatorStrategy LocatorOf = LocatorStrategy.PartialLinkText;
    else static if (strategy == "tag")
        enum LocatorStrategy LocatorOf = LocatorStrategy.TagName;
    else static if (strategy == "xpath")
        enum LocatorStrategy LocatorOf = LocatorStrategy.XPath;
    else
        static assert(false, "Unknown locator strategy: " ~ strategy);
}
```

Used in template constraints:

```d
Element findOne(string strategy)(string value)
    if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
```

This provides:
- Compile-time validation of strategy strings
- No runtime `ElementLocator` construction for the common case
- Clean call sites: `driver.findOne!"id"("foo")`

## File Size Targets

| Module | Target Lines | Rationale |
|--------|-------------|-----------|
| `errors.d` | ~40 | Small exception hierarchy |
| `types.d` | ~180 | Enums + structs |
| `locator.d` | ~50 | Struct + 8 factories |
| `protocol/client.d` | ~120 | HTTP client |
| `protocol/response.d` | ~80 | Response parsing |
| `driver.d` | ~250 | Process + session |
| `element.d` | ~180 | Properties + scoped search |
| `page.d` | ~50 | Simple base class |
| `package.d` | ~15 | Re-exports |
