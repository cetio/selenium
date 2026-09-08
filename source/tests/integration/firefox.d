/// Firefox integration tests.
/// This module is only compiled when the `--d-version=firefox` flag is used.
///
/// All tests in this module which require use the driver instance must be `@Serial` because they share live browser sessions.
module tests.integration.firefox;

version(firefox)
{
    import tests.common : BrowserIntegration;

    mixin BrowserIntegration!"firefox";
}
