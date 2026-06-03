module selenium.error;

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

static WebDriverError mapError(ushort status, JSONValue json)
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
