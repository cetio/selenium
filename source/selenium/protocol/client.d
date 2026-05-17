module selenium.protocol.client;

import std.json : JSONType, JSONValue, parseJSON;
import std.net.curl : HTTP;

import conductor.http : Response, send;
import conductor.serialize.json : fromJSON;

import selenium.errors : WebDriverError;
import selenium.protocol.response : checkAndParse;
import selenium.types : WebElement;

public:

class Client
{
private:
    string _serverUrl;
    string _sessionId;

public:
    this(string serverUrl, string sessionId)
    {
        _serverUrl = serverUrl;
        _sessionId = sessionId;
    }

    string serverUrl() const
        => _serverUrl;

    string sessionId() const
        => _sessionId;

    void delete_(string path)
    {
        request(HTTP.Method.del, sessionPath(path));
    }

    void delete_(T)(string path, T body_)
    {
        request(HTTP.Method.del, sessionPath(path), body_);
    }

    void post(string path)
    {
        request(HTTP.Method.post, sessionPath(path));
    }

    void post(T)(string path, T body_)
    {
        request(HTTP.Method.post, sessionPath(path), body_);
    }

    T get(T)(string path)
    {
        return parse!T(request(HTTP.Method.get, sessionPath(path)));
    }

    T post(T)(string path)
    {
        return parse!T(request(HTTP.Method.post, sessionPath(path)));
    }

    T post(T, U)(string path, U body_)
    {
        return parse!T(request(HTTP.Method.post, sessionPath(path), body_));
    }

    void disconnect()
    {
        delete_("");
    }

private:
    string sessionPath(string path)
    {
        return _serverUrl ~ "/session/" ~ _sessionId ~ path;
    }

    JSONValue request(HTTP.Method method, string url)
    {
        HTTP http = HTTP();
        Response response = send(http, method, url);
        return checkAndParse(response);
    }

    JSONValue request(T)(HTTP.Method method, string url, T body_)
    {
        HTTP http = HTTP();
        Response response = send(http, method, url, body_);
        return checkAndParse(response);
    }

    static T parse(T)(JSONValue json)
    {
        static if (is(T == WebElement))
            return parseWebElement(json);
        else static if (is(T == WebElement[]))
            return parseWebElements(json);
        else
        {
            if ("value" in json)
                return fromJSON!T(json["value"]);

            return fromJSON!T(json);
        }
    }

    static WebElement parseWebElement(JSONValue json)
    {
        enum W3C_KEY = "element-6066-11e4-a52e-4f735466cecf";

        JSONValue value = ("value" in json) ? json["value"] : json;

        if (value.type == JSONType.object)
        {
            if (W3C_KEY in value && value[W3C_KEY].type == JSONType.string)
                return WebElement(value[W3C_KEY].str);
            if ("ELEMENT" in value && value["ELEMENT"].type == JSONType.string)
                return WebElement(value["ELEMENT"].str);
        }

        return WebElement.init;
    }

    static WebElement[] parseWebElements(JSONValue json)
    {
        JSONValue value = ("value" in json) ? json["value"] : json;

        WebElement[] ret;
        if (value.type == JSONType.array)
        {
            foreach (item; value.array)
                ret ~= parseWebElement(item);
        }

        return ret;
    }
}
