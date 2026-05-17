# 01 — Current State & Problem Analysis

## File Inventory

| File | Lines | Role | Status |
|------|-------|------|--------|
| `source/selenium/api.d` | 912 | Enums, structs, exceptions, HTTP plumbing, all WebDriver protocol methods | Inherited; monolithic; legacy JsonWireProtocol |
| `source/selenium/session.d` | 519 | Session wrapper, element wrapper, cookie/navigation/window sub-classes | Inherited; `immutable class` everywhere; `@property` blocks |
| `source/selenium/workflow.d` | 247 | Template-based page object framework (`Workflow`, `WorkflowCheck`, etc.) | Inherited; unmaintainable `opDispatch` soup |
| `source/selenium/driver.d` | 170 | Browser driver process management | Written for this fork; best-shaped but needs cleanup |
| `source/tests/behaviors.d` | 128 | Static unit tests for types and locators | Tests old API |
| `source/tests/dynamic.d` | 48 | Integration test against real WebDriver | Tests old `immutable` session API |

## Critical Convention Violations

### `immutable class` Abuse
`SeleniumSession`, `SeleniumApi`, `SeleniumApiConnection`, `SeleniumWindow`, `SeleniumNavigation`, and `Element` are all declared `immutable class`. This is a D anti-pattern that forces every instance onto the immutable data segment, prevents natural mutation patterns, and complicates every call site with `new immutable` and `inout`/`immutable` qualifiers.

### `@property` Everywhere
`session.d` uses `@property` blocks extensively. Per our rules, property-style accessors must use lambda syntax with `ref` / `auto ref` and be invoked via UFCS without parentheses.

### `auto` Return Types
Nearly every function in the inherited files uses `auto`. This is only permitted when the type is impossible to specify or is an extremely long `typeof` expression.

### Missing Access Modifier Sections
Code is not grouped under `private:`, `package:`, or `public:` labels.

### Missing Selective Imports
`import std.stdio`, `import std.json` instead of `import std.json : JSONValue, parseJSON`.

### Tab Indentation
All inherited files use tabs instead of spaces.

### Redundant `Selenium` Prefix
Inside the `selenium` package, `SeleniumSession`, `SeleniumApi`, `SeleniumException`, `SeleniumWindow`, etc. are unnecessarily verbose.

### No `package.d` Files
The project does not use D's module re-export system.

## Architectural Problems

### Monolithic `api.d`
912 lines containing:
- Exception types
- Enums (`Browser`, `Platform`, `LocatorStrategy`, `MouseButton`, etc.)
- Structs (`Capabilities`, `Cookie`, `Size`, `Position`, `WebElement`, etc.)
- HTTP connection classes (`SeleniumApiConnector`, `SeleniumApiConnection`)
- The entire WebDriver protocol surface (`SeleniumApi` with ~90 methods)

No separation of concerns. Any change to one concern requires editing a 900-line file.

### Excessive Indirection
`SeleniumApiConnector` exists only to construct `SeleniumApiConnection` and `SeleniumApi`. Three classes where one `Client` would suffice.

### Nested Helpers in `session.d`
`SeleniumCookie`, `SeleniumNavigation`, `SeleniumWindow` are nested classes inside `session.d`. They should be standalone concerns or removed entirely in favor of direct methods.

### `workflow.d` is Dead Weight
Complex `opDispatch`-based page object framework with `WorkflowCheck`, `WorkflowNamed`, and `Workflow` templates. This is a framework-within-a-library that should be replaced with a simple `Page` base class.

## Protocol Problems

The code was written for the old Selenium **JSON Wire Protocol**:
- `ELEMENT` field for element IDs
- `status` integer codes in responses
- `SessionResponse!T` wrapper struct
- `/window_handle`, `/window_handles`, `/timeouts/implicit_wait` endpoints

Modern **W3C WebDriver** uses different response shapes, different element ID keys, and has deprecated or removed endpoints such as `/touch/*`, `/local_storage`, `/session_storage`, `/ime/*`, `/application_cache`, `/orientation`, `/location`.

The current code has partial compatibility patches but is structurally wired to the old protocol.
