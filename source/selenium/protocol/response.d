module selenium.protocol.response;

import std.json : JSONValue, JSONType, parseJSON;

import conductor.http : Response;

import selenium.errors :
    InvalidElementStateError,
    NoSuchElementError,
    StaleElementReferenceError,
    WebDriverConnectionError,
    WebDriverError,
    WebDriverTimeoutError;

public:

JSONValue checkAndParse(Response response)
{
    JSONValue ret = parseJSON(cast(string)response.content);

    if (response.status >= 400)
        throw mapError(response.status, ret);

    return ret;
}

private:

WebDriverError mapError(ushort status, JSONValue json)
{
    string message = extractMessage(json);

    if ("value" in json && json["value"].type == JSONType.object)
    {
        JSONValue value = json["value"];
        if ("error" in value && value["error"].type == JSONType.string)
        {
            string errorCode = value["error"].str;

            switch (errorCode)
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
        long statusCode = json["status"].type == JSONType.integer
            ? json["status"].get!long
            : 0;

        switch (statusCode)
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

string extractMessage(JSONValue json)
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
