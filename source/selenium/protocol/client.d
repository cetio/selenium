module selenium.protocol.client;

import std.json : JSONValue, parseJSON;
import std.net.curl : HTTP;

import conductor.http : Response, send;
import conductor.serialize.json : fromJSON;

import selenium.errors : WebDriverError;
import selenium.protocol.response : checkAndParse;

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
        delete_("/");
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
        if ("value" in json)
            return fromJSON!T(json["value"]);

        return fromJSON!T(json);
    }
}
