/// Chrome integration tests.
/// This module is only compiled when the `--d-version=chrome` flag is used.
///
/// All tests in this module which require use the driver instance must be `@Serial` because they share live browser sessions.
module tests.integration.chrome;

