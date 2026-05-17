# 04 — Convention Compliance Checklist

Every new or rewritten file must pass the following checklist derived from `global_rules.md`.

## Naming

- [ ] No 1-2 letter names except loop indices and legitimate compound abbreviations
- [ ] Fields are more descriptive than corresponding locals (`_session` vs `session`)
- [ ] Every return variable is named `ret`
- [ ] No useless indirection or wrapper variables
- [ ] No comment separators or section headers inside files
- [ ] No underscores in file names unless necessary; no overly brief files
- [ ] Accessors invoked via UFCS without parentheses (no `@property`)

### Applied Examples

| Before | After | Rationale |
|--------|-------|-----------|
| `webdriver_remote_sessionid` | `remoteSessionId` | Descriptive, no underscores |
| `element` (local) | `webElement` | Clearer than `element` in element context |
| `sel` / `cls` | `session` / `child` | No 1-2 letter names |
| `SeleniumSession` | `Session` | Package context removes need for prefix |
| `SeleniumApi` | `Client` | Matches reference projects |
| `classLocator` | `byClass` | Call-site reads naturally |
| `isSelected()` / `isEnabled()` | `selected()` / `enabled()` | UFCS-friendly, no `is` prefix |

## Types and Values

- [ ] Every enum value uses `PascalCase`; every enum variable uses `camelCase`; every enum function uses `PascalCase`
- [ ] Compile-time value symbols (not templates) are `ALL_CAPS` and brief
- [ ] Alias variables are `ALL_CAPS` and brief
- [ ] Templates holding data use `PascalCase`; template functions use `camelCase`

### Applied Examples

| Before | After |
|--------|-------|
| `enum Browser { chrome = "chrome" }` | `enum Browser { Chrome = "chrome" }` |
| `enum Platform { Windows = "Windows" }` | `enum Platform { Windows = "Windows" }` (already correct) |
| `LocatorStrategy using` | `LocatorStrategy strategy` (field clearer than keyword) |

## Members

- [ ] Private members with wrappers/accessors that must be used rather than the field, use underscore before the name (`_session`, `_client`, `_driver`)

## Formatting

- [ ] 4+ parameter declarations, calls, and array literals are split across lines
- [ ] Outer scoped statements containing nested statements use braces
- [ ] Inner scoped statements with multiple statements use braces
- [ ] No single-line scoped statement without nesting uses braces
- [ ] No scoped statement body on the same line as its condition
- [ ] No function body on the same line as its signature
- [ ] Every delegate literal uses braces

## Whitespace

- [ ] No space around `..`, `~`, `cast`, or `$-X`
- [ ] Consistent spacing around binary operators
- [ ] Space after every comma in lists
- [ ] No trailing whitespace; no alignment padding
- [ ] Every function declaration followed by a blank line
- [ ] No blank line before a scoped statement when the prior line is closely related
- [ ] Every scoped statement followed by a blank line unless the next line is a return

## Auto and Temporaries

- [ ] No `auto` unless the type is impossible to specify
- [ ] No variable introduced solely to immediately return or pass its value

### Applied Examples

| Before | After |
|--------|-------|
| `auto connector = new SeleniumApiConnector(...)` | `Client client = new Client(serverUrl, sessionId)` |
| `auto ret = connector.api` | (removed; direct assignment) |
| `auto url() { return api.url; }` | `string url() { return _client.get!string("/url"); }` |

## Imports

- [ ] All imports at the top except inside conditional compilation
- [ ] Every imported symbol is referenced; no unused imports remain
- [ ] No convenience imports unless genuinely required
- [ ] Selective imports replace blanket imports where applicable
- [ ] Project-specific imports precede standard library imports

### Applied Examples

```d
// Before
import std.stdio;
import std.json;

// After
import selenium.errors : WebDriverError;
import selenium.types : Capabilities;
import std.json : JSONValue, parseJSON;
```

## Access and Organization

- [ ] Code grouped under `private:`, `package:`, and `public:` labels
- [ ] `__gshared` is completely pointless and should not be used

## Functions

- [ ] No `@property` attribute
- [ ] Property-style accessors use lambda syntax with `ref` / `auto ref` and UFCS
- [ ] Every static method uses `static` explicitly
- [ ] Every template constraint uses `if (is(...))` syntax

### Applied Examples

```d
// Before
@property {
    immutable(SeleniumWindow) currentWindow() {
        return new immutable SeleniumWindow(api, this);
    }
}

// After
string windowHandle()
{
    return _client.get!string("/window");
}

// Lambda accessor
string url() const
    => _url;
```

## Line Length

- [ ] No line exceeds 120 characters except mixins

## File Organization

- [ ] Module declaration first, imports second, sections third, implementation last

### Applied Structure

```d
module selenium.driver;

import selenium.element : Element;
import selenium.errors : WebDriverConnectionError;
import selenium.locator : ElementLocator;
import selenium.protocol.client : Client;
import selenium.types : Capabilities, LocatorStrategy;
import conductor.http : Response, send;
import std.conv : to;
import std.json : JSONValue;
import std.net.curl : HTTP;
import std.process : execute, Pid, spawnProcess;
import std.socket : AddressFamily, InternetAddress, Socket;
import std.string : strip;
import core.thread : Thread;
import core.time : MonoTime, msecs;

public:

enum DriverType { ... }

class Driver
{
private:
    // fields

public:
    // methods

package:
    // element-scoped query helpers

private:
    // implementation helpers
}
```
