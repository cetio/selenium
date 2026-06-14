module selenium.exception;

import std.exception : basicExceptionCtors;
import std.json : JSONValue, JSONType;

class WebDriverException : Exception
{
    mixin basicExceptionCtors;
}

class NoSuchElementException : WebDriverException
{
    mixin basicExceptionCtors;
}

class StaleElementReferenceException : WebDriverException
{
    mixin basicExceptionCtors;
}

class InvalidElementStateException : WebDriverException
{
    mixin basicExceptionCtors;
}

class WebDriverTimeoutException : WebDriverException
{
    mixin basicExceptionCtors;
}

class WebDriverConnectionException : WebDriverException
{
    mixin basicExceptionCtors;
}

class InvalidArgumentException : WebDriverException
{
    mixin basicExceptionCtors;
}

class InvalidSelectorException : WebDriverException
{
    mixin basicExceptionCtors;
}

class InvalidSessionIdException : WebDriverException
{
    mixin basicExceptionCtors;
}

class JavaScriptException : WebDriverException
{
    mixin basicExceptionCtors;
}

class ElementNotInteractableException : WebDriverException
{
    mixin basicExceptionCtors;
}

class ElementClickInterceptedException : WebDriverException
{
    mixin basicExceptionCtors;
}

class NoSuchWindowException : WebDriverException
{
    mixin basicExceptionCtors;
}

class NoSuchFrameException : WebDriverException
{
    mixin basicExceptionCtors;
}

class ScriptTimeoutException : WebDriverException
{
    mixin basicExceptionCtors;
}

class UnknownCommandException : WebDriverException
{
    mixin basicExceptionCtors;
}

class UnsupportedOperationException : WebDriverException
{
    mixin basicExceptionCtors;
}

class UnexpectedAlertOpenException : WebDriverException
{
    mixin basicExceptionCtors;
}

class NoSuchAlertException : WebDriverException
{
    mixin basicExceptionCtors;
}

class UnableToSetCookieException : WebDriverException
{
    mixin basicExceptionCtors;
}

package:

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
