module selenium.error;

import std.exception : basicExceptionCtors;
import std.json : JSONValue, JSONType;

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

class InvalidArgumentError : WebDriverError
{
    mixin basicExceptionCtors;
}

class InvalidSelectorError : WebDriverError
{
    mixin basicExceptionCtors;
}

class InvalidSessionIdError : WebDriverError
{
    mixin basicExceptionCtors;
}

class JavaScriptError : WebDriverError
{
    mixin basicExceptionCtors;
}

class ElementNotInteractableError : WebDriverError
{
    mixin basicExceptionCtors;
}

class ElementClickInterceptedError : WebDriverError
{
    mixin basicExceptionCtors;
}

class NoSuchWindowError : WebDriverError
{
    mixin basicExceptionCtors;
}

class NoSuchFrameError : WebDriverError
{
    mixin basicExceptionCtors;
}

class ScriptTimeoutError : WebDriverError
{
    mixin basicExceptionCtors;
}

class UnknownCommandError : WebDriverError
{
    mixin basicExceptionCtors;
}

class UnsupportedOperationError : WebDriverError
{
    mixin basicExceptionCtors;
}

class UnexpectedAlertOpenError : WebDriverError
{
    mixin basicExceptionCtors;
}

package:

static WebDriverError mapError(JSONValue json)
{
    string message = extractMessage(json);

    if ("value" in json && json["value"].type == JSONType.object)
    {
        JSONValue value = json["value"];
        if ("error" in value && value["error"].type == JSONType.string)
        {
            switch (value["error"].str)
            {
                case "no such element":
                    return new NoSuchElementError(message);
                case "stale element reference":
                    return new StaleElementReferenceError(message);
                case "invalid element state":
                    return new InvalidElementStateError(message);
                case "timeout":
                    return new WebDriverTimeoutError(message);
                case "session not created":
                    return new WebDriverConnectionError(message);
                case "invalid argument":
                    return new InvalidArgumentError(message);
                case "invalid selector":
                    return new InvalidSelectorError(message);
                case "invalid session id":
                    return new InvalidSessionIdError(message);
                case "javascript error":
                    return new JavaScriptError(message);
                case "element not interactable":
                    return new ElementNotInteractableError(message);
                case "element click intercepted":
                    return new ElementClickInterceptedError(message);
                case "no such window":
                    return new NoSuchWindowError(message);
                case "no such frame":
                    return new NoSuchFrameError(message);
                case "script timeout":
                    return new ScriptTimeoutError(message);
                case "unknown command":
                    return new UnknownCommandError(message);
                case "unknown method":
                    return new UnknownCommandError(message);
                case "unsupported operation":
                    return new UnsupportedOperationError(message);
                case "unexpected alert open":
                    return new UnexpectedAlertOpenError(message);
                default:
                    return new WebDriverError(message);
            }
        }
    }

    if ("status" in json)
    {
        switch (json["status"].type == JSONType.integer ? json["status"].get!long : 0)
        {
            case 7:
                return new NoSuchElementError(message);
            case 10:
                return new StaleElementReferenceError(message);
            case 12:
                return new InvalidElementStateError(message);
            case 21:
                return new WebDriverTimeoutError(message);
            case 33:
                return new WebDriverConnectionError(message);
            default:
                return new WebDriverError(message);
        }
    }

    return new WebDriverError(message);
}


private:

static string extractMessage(JSONValue json)
{
    if ("value" in json && json["value"].type == JSONType.object)
    {
        JSONValue value = json["value"];
        if ("message" in value && value["message"].type == JSONType.string)
            return value["message"].str;
    }

    if ("message" in json && json["message"].type == JSONType.string)
        return json["message"].str;

    return "WebDriver server error";
}