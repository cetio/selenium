# Testing

The repository has offline unit tests and browser integration tests. Both use [unit-threaded](https://github.com/atilaneves/unit-threaded) and the generated runner at `bin/ut.d`.

- **Offline tests** cover capability serialization, response parsing, Grid models, and in-process routing without launching a browser.
- **Browser integration tests** share a live Chrome or Firefox session and exercise navigation, windows, frames, scripts, elements, and roots.

## Prerequisites

Install [DUB](https://dub.pm) and a D compiler. Browser integration tests additionally require the selected browser and its WebDriver executable on `PATH`:

| Version flag | Browser | WebDriver executable |
| --- | --- | --- |
| `chrome` | Chrome | `chromedriver` |
| `firefox` | Firefox | `geckodriver` |

The integration setup calls `resolveBinary()` and fails if the executable cannot be found. Browsers are not skipped automatically.

## Running Tests

| Version | Meaning |
| --- | --- |
| `--d-version=chrome` | Includes Chrome integration tests. |
| `--d-version=firefox` | Includes Firefox integration tests. |

Run the offline suite:

```sh
dub test
```

Run the offline suite plus one browser integration suite:

```sh
dub test --d-version=chrome
dub test --d-version=firefox
```

Run a subpackage's offline tests:

```sh
dub test :webdriver
dub test :grid
```

Pass a unit-threaded test name after `--` to filter a run. Include the browser version flag when filtering for a browser integration test:

```sh
dub test -- "Browser roundtrips platform, strategy, and timeouts"
dub test --d-version=chrome -- "click updates button text"
dub test --d-version=firefox -- "frame switch by index"
```

## Test Layout

| Path | Purpose |
| --- | --- |
| `source/tests/webdriver/browser.d` | Browser capability, logging, and JSON roundtrip tests. |
| `source/tests/webdriver/driver/` | Offline locator, response parsing, and bridge-capacity tests. |
| `source/tests/grid/server.d` | Grid models, router dispatch, hub behavior, and node behavior. |
| `source/tests/common.d` | `dataUri` and the shared `BrowserIntegration` mixin. |
| `source/tests/integration/chrome.d` | Chrome session setup under `version (chrome)`. |
| `source/tests/integration/firefox.d` | Firefox session setup under `version (firefox)`. |
| `bin/ut.d` | Generated unit-threaded runner. Do not edit it manually. |

DUB runs `unit-threaded`'s `gen_ut_main` pre-build command to regenerate `bin/ut.d` from `source/tests`.

## Writing Tests

Name tests with `@Name` so individual cases can be selected from the command line. Keep offline tests independent of installed browsers and network services.

Add browser-independent assertions to the appropriate module under `source/tests/webdriver` or `source/tests/grid`. Add live behavior shared by Chrome and Firefox to `BrowserIntegration` in `source/tests/common.d`. Integration tests share one session per browser module and must use `@Serial`.

```d
@Name("By.css serializes correctly")
unittest
{
    By.css("#submit").toJSON()["using"].str.should == "css selector";
}
```

A shared live test in `BrowserIntegration` uses the browser module's `driver` accessor:

```d
@Name("click updates button text") @Serial
unittest
{
    driver.go(dataUri(
        "<html><body><button id='button' "
        ~"onclick='this.textContent=\"clicked\"'>click</button></body></html>"
    ));
    driver.find(By.css("#button")).click();
    driver.find(By.css("#button")).text.should == "clicked";
}
```

When adding support for another integration browser, create a module under `source/tests/integration`, gate its setup with a browser-specific `version (...)`, construct the browser and bridge, and mixin `BrowserIntegration`. Add the same version identifier to the CI browser matrix.

### Test Pages

Use `dataUri` from `tests.common` for small, self-contained pages:

```d
driver.go(dataUri("<html><body><p id='text'>test</p></body></html>"));
```

This keeps browser integration tests deterministic and avoids external network dependencies.

## Browser Setup and Debugging

Chrome integration tests always launch Chrome with `--no-sandbox` and `--headless`. Firefox tests always launch Firefox with `--headless`.

WebDriver process logs are suppressed with `--log-level=OFF` and `--log fatal`, respectively.

If an integration test fails:

- Confirm the browser and matching WebDriver executable are installed and on `PATH`.
- Confirm the browser and WebDriver versions are compatible.
- Temporarily relax the WebDriver log arguments in the corresponding `source/tests/integration` module.
- Filter to the failing `@Name` while iterating.

## CI/CD

The [Browser Integration workflow](.github/workflows/browser-integration.yml) runs on pushes and pull requests targeting `master`. Its matrix uses:

- `ldc-latest`. (DMD will cause false negatives on MacOS)
- Ubuntu, Windows, and macOS GitHub-hosted runners.
- Chrome and Firefox.

Each matrix entry runs:

```sh
dub test --d-version=<browser>
```

This executes the offline tests and the selected browser integration suite.
