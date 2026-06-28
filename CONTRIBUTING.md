# Contributing to Selenium

Thanks for your interest in contributing. This documentation covers how contributions should be formatted, the testing system, and guidelines.

## Reporting Issues

- Search existing issues before opening a new one to avoid duplicates.
- For bugs, include:
  - Steps to reproduce.
  - Expected behavior vs. actual behavior.
  - Environment details (OS, D compiler and version, WebDriver and browser versions).
  - Relevant logs or a minimal reproduction where possible.

## Suggesting Features

- Open an issue with a clear description of the feature.
- Explain the use case and how it fits the WebDriver protocol surface the library exposes.

## Pull Requests

- Fork the repository and work on a branch. A descriptive name like `feature/log-draining` helps but is not required.
- Write commit messages that make it clear what changed and why.
- Keep changes focused and consistent with the existing design. All changes should make sense and be easy to intuit for someone who knows the codebase.
- Every new feature or bug fix must ship with tests. See the next section.

## Tests

Tests are required for any new feature or bug fix. The full testing workflow, directory layout, and conventions live in [TESTING.md](TESTING.md), and contributions are expected to comply with it.

At minimum:

- Add an **offline test** when the change involves parsing, serialization, or JSON roundtrips.
- Add an **integration test** when the change involves live WebDriver behavior.
- Cover both success and error paths where possible, and gate live tests behind `version (integration)`.

Offline tests must pass before a pull request is considered:

```sh
dub test
```

Run integration tests locally when your change touches live behavior:

```sh
dub run -c integration
```

To test a specific subpackage only:

```sh
dub test :webdriver -c unittest
dub run :grid -c integration
```

See [TESTING.md](TESTING.md) for browser configuration, naming, filtering, and debugging.

## Code Style

- Document public types and functions. Follow the existing ddoc style, and note explicitly where something resembles the W3C specification but deviates from it.
- Keep code readable and avoid unnecessary dependencies.
- Do not touch the build system in `dub.json` unless your change must integrate with it.

## Communication and Conduct

- Ask questions and discuss ideas in issues or pull request comments.
- Be respectful and constructive.

## License

By contributing, you agree that your contributions are licensed under the same license as Selenium ([Apache-2.0](LICENSE.txt)).