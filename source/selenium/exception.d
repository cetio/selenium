/// WebDriver error hierarchy and mapping from server error responses.
module selenium.exception;

import std.exception : basicExceptionCtors;
import std.json : JSONValue, JSONType;

/// Base type for every error raised by the library.
class WebDriverException : Exception
{
    mixin basicExceptionCtors;
}

/// No element matched the requested locator.
class NoSuchElementException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The referenced element is no longer attached to the DOM.
class StaleElementReferenceException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The element is in a state that does not permit the command.
class InvalidElementStateException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// A command did not complete within its configured timeout.
class WebDriverTimeoutException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The driver process could not be reached or a session could not be created.
class WebDriverConnectionException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// A command argument was missing or malformed.
class InvalidArgumentException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The selector expression was not valid for its strategy.
class InvalidSelectorException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The session id is unknown, which usually means the session has ended.
class InvalidSessionIdException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// Injected JavaScript threw an error during evaluation.
class JavaScriptException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The element cannot receive the attempted interaction.
class ElementNotInteractableException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// Another element intercepted the click on the target element.
class ElementClickInterceptedException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The targeted window or tab no longer exists.
class NoSuchWindowException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The targeted frame could not be found.
class NoSuchFrameException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// An asynchronous script did not complete within the script timeout.
class ScriptTimeoutException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The driver does not recognize the requested command.
class UnknownCommandException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The driver recognizes the command but does not support it.
class UnsupportedOperationException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// A user prompt is open and blocking the command.
class UnexpectedAlertOpenException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// No user prompt is currently open.
class NoSuchAlertException : WebDriverException
{
    mixin basicExceptionCtors;
}

/// The cookie could not be set, often due to a domain mismatch.
class UnableToSetCookieException : WebDriverException
{
    mixin basicExceptionCtors;
}

package:

/**
 * Maps a server error response to the most specific exception type.
 *
 * Prefers the W3C `value.error` string and falls back to the legacy numeric
 * `status` code when no error string is present.
 *
 * Params:
 *  json = The parsed error response body.
 *
 * Returns:
 *  The matching exception, or a base WebDriverException when unrecognized.
 */
static WebDriverException mapException(JSONValue json)
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
                    return new NoSuchElementException(message);
                case "stale element reference":
                    return new StaleElementReferenceException(message);
                case "invalid element state":
                    return new InvalidElementStateException(message);
                case "timeout":
                    return new WebDriverTimeoutException(message);
                case "session not created":
                    return new WebDriverConnectionException(message);
                case "invalid argument":
                    return new InvalidArgumentException(message);
                case "invalid selector":
                    return new InvalidSelectorException(message);
                case "invalid session id":
                    return new InvalidSessionIdException(message);
                case "javascript error":
                    return new JavaScriptException(message);
                case "element not interactable":
                    return new ElementNotInteractableException(message);
                case "element click intercepted":
                    return new ElementClickInterceptedException(message);
                case "no such window":
                    return new NoSuchWindowException(message);
                case "no such frame":
                    return new NoSuchFrameException(message);
                case "script timeout":
                    return new ScriptTimeoutException(message);
                case "unknown command":
                    return new UnknownCommandException(message);
                case "unknown method":
                    return new UnknownCommandException(message);
                case "unsupported operation":
                    return new UnsupportedOperationException(message);
                case "unexpected alert open":
                    return new UnexpectedAlertOpenException(message);
                case "no such alert":
                    return new NoSuchAlertException(message);
                case "unable to set cookie":
                    return new UnableToSetCookieException(message);
                default:
                    return new WebDriverException(message);
            }
        }
    }

    if ("status" in json)
    {
        switch (json["status"].type == JSONType.integer ? json["status"].get!long : 0)
        {
            case 7:
                return new NoSuchElementException(message);
            case 10:
                return new StaleElementReferenceException(message);
            case 12:
                return new InvalidElementStateException(message);
            case 21:
                return new WebDriverTimeoutException(message);
            case 33:
                return new WebDriverConnectionException(message);
            default:
                return new WebDriverException(message);
        }
    }

    return new WebDriverException(message);
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
