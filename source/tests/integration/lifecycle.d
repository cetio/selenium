module tests.integration.lifecycle;

import selenium.browser.chrome : defaultChrome;
import selenium.driver : Driver;
import selenium.error : WebDriverConnectionError;
import selenium.options : Options;

import std.conv : octal;
import std.exception : assertThrown;
import std.file : mkdirRecurse, setAttributes, write;
import std.path : buildPath;
import std.process : environment;
import std.uuid : randomUUID;

private string isolatedPath()
{
    string ret = buildPath("/tmp", "selenium-sdk-test-"~randomUUID().toString());
    mkdirRecurse(ret);
    string shim = buildPath(ret, "which");
    write(shim, "#!/bin/sh\nexit 1\n");
    setAttributes(shim, octal!755);
    return ret;
}

unittest
{
    string original = environment.get("PATH", "");
    environment["PATH"] = isolatedPath();
    scope(exit)
        environment["PATH"] = original;

    assertThrown!WebDriverConnectionError(Driver.start());
}

unittest
{
    string original = environment.get("PATH", "");
    environment["PATH"] = isolatedPath();
    scope(exit)
        environment["PATH"] = original;

    assertThrown!WebDriverConnectionError(Driver.start(Options(defaultChrome)));
}