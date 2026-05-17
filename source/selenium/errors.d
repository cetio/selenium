module selenium.errors;

import std.exception : basicExceptionCtors;

class WebDriverError : Exception
{
    mixin basicExceptionCtors;
}

class NoSuchElementError : WebDriverError
{
    mixin basicExceptionCtors;
}

class StaleElementReferenceError : WebDriverError
{
    mixin basicExceptionCtors;
}

class InvalidElementStateError : WebDriverError
{
    mixin basicExceptionCtors;
}

class WebDriverTimeoutError : WebDriverError
{
    mixin basicExceptionCtors;
}

class WebDriverConnectionError : WebDriverError
{
    mixin basicExceptionCtors;
}
