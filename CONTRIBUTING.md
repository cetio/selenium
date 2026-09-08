# Contributing to Selenium

Thanks for contributing to Selenium. Keep changes focused, follow the existing design and D style, and include tests for behavioral changes.

## Reporting Issues

Search existing issues before opening a new one. Bug reports should include:

- Steps to reproduce and a minimal example when possible.
- Expected and actual behavior.
- Operating system and D compiler version.
- Browser and WebDriver executable versions for live-session failures.
- Relevant client or WebDriver logs without credentials or other sensitive data.

Feature requests should describe the use case, expected API, and relationship to the W3C WebDriver protocol or existing Grid scaffolding.

## Development Setup

Install [DUB](https://dub.pm), a D compiler, and the dependencies resolved by DUB. Chrome and Firefox integration tests also require the matching browser and WebDriver executable on `PATH`:

| Browser version flag | Required executable |
| --- | --- |
| `chrome` | `chromedriver` |
| `firefox` | `geckodriver` |

The project does not download browsers or WebDriver executables, and a missing executable fails the corresponding integration-test run.

## Pull Requests

- Work on a focused branch and explain both what changed and why.
- Follow the conventions in neighboring modules. Avoid unnecessary dependencies or abstractions.
- Document public types and functions with the existing Ddoc style.
- Call out intentional differences from the W3C specification.
- Update user and contributor documentation when commands, public APIs, or supported behavior change.
- Add tests for every bug fix and feature.

## Tests

Run all offline tests before submitting a pull request:

```sh
dub test
```

Run each relevant browser integration suite when changing live WebDriver behavior:

```sh
dub test --d-version=chrome
dub test --d-version=firefox
```

These commands run the offline suite as well as the selected browser-gated tests. Run a subpackage's offline tests with:

```sh
dub test :webdriver
dub test :grid
```

Use the root package for the browser integration suites. See [TESTING.md](TESTING.md) for the test layout, filtering syntax, browser setup, and CI matrix.

## Review Checklist

Before opening a pull request:

1. Run the relevant offline and browser tests.
2. Confirm new tests fail without the fix when practical.
3. Review the diff for generated files, unrelated changes, and sensitive data.
4. Verify documentation examples and links affected by the change.

## Communication and Conduct

Ask questions in issues or pull request comments, and keep discussions respectful and constructive.

## License

By contributing, you agree that your contributions are licensed under the same [Apache-2.0 license](LICENSE.txt) as Selenium.
