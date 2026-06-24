# Tests

Tests are split up into offline and integration tests.

- **Offline tests** cover behaviors that do not require real sessions (parsing, serialization, JSON roundtrips) and can be run with `dub test`.
- **Integration tests** launch real driver sessions against installed browsers and can be run with `dub test -c integration`.

## Prerequisites

- [DUB](https://dub.pm) and a D compiler (DMD or LDC).
- For integration tests, Chrome and Firefox are defaults, but this can be configured easily by modifying `tests.common`'s `configs` array to set up your own browser configurations.

Browsers that cannot be found are skipped with a console message.

## Directory Structure

| Module | What it covers |
| --- | --- |
| `tests.browser` | Browser capability serialization, `fromJSONValue`/`toJSON` roundtrips, logging prefs, and driver argument generation. |
| `tests.driver.element` | Element interaction: click, sendKeys, clear, find, nested find, cssValue, selected/enabled state, stale element handling. |
| `tests.driver.frame` | `By` strategy serialization, frame switching by index/element/parent/top. |
| `tests.driver.script` | JavaScript execution, argument passing, return type coercion, script error handling. |
| `tests.driver.window` | Element ID parsing, window title, handles, resize, maximize, minimize. |
| `tests.common` | Shared helpers: `dataUri`, `testAll`, and the integration-test `configs` initializer. |

## Running Tests

Run offline tests only:

```sh
dub test
```

Run all tests including integration tests:

```sh
dub test -c integration
```

Pass a name pattern after `--` to limit which tests execute:

```sh
dub test -- "click updates button text"
dub test -c integration -- "frame switch"
```

## Test Framework

Tests use [unit-threaded](https://github.com/atilaneves/unit-threaded). The runner is auto-generated via `gen_ut_main` during the pre-build step (see `dub.json`). Tests are named with `@Name("...")` so they can be filtered from the command line.

Integration tests use `@Serial` because they share live browser sessions and are not safe to run in parallel.

## Configuring Browsers

The integration test matrix is defined in `tests.common` in the `configs` static constructor. By default it attempts Chrome and Firefox with suppressive log levels to keep output clean.

To add a browser, append to `configs` inside the `version(integration)` block:

```d
Edge edge = new Edge();
if (edge.isInstalled)
    configs ~= TestConfig(edge, Bridge.start(edge.resolveBinary(false), []));
```

## Writing New Tests

All new tests must test behavior and should not be shallow, meaning they must test behavior that is not fixed.

A good test is minimal and isolated. When adding a new feature, add an offline test if it involves parsing or serialization, and an integration test if it involves WebDriver behavior. Test both success paths and error paths where possible.

If a feature has different live vs offline behavior, the test file should contain both kinds of tests, using `version (integration)` to gate the live ones:

```d
// Offline: always compiled
@Name("By.css serializes correctly")
unittest { ... }

version(integration)
{
    import tests.common;

    @Name("click updates button text") @Serial
    unittest { testAll((driver) { ... }); }
}
```

### Test Pages

If constructing your own pages for integration tests, you can use the `dataUri` helper in `tests.common` to create HTML pages inline:

```d
driver.go(dataUri("<html><body><p id='t'>test</p></body></html>"));
```

## Debugging

- If an integration test fails, the browser binary and bridge logs may contain the real error. The default configs suppress most driver output; temporarily remove `--log-level=OFF` or `--log fatal` in `tests.common` to see verbose output.
- If a browser is skipped unexpectedly, verify it is on your `PATH` or use the absolute path via the browser's `binary` field.
- Offline tests should never depend on a browser being installed. If `dub test` fails, it is a code bug, not an environment issue.

## CI

Integration tests require installed browsers, so they are primarily intended for local development. Offline tests (`dub test`) are safe to run in any CI environment.