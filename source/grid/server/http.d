/// Server-side HTTP request and response primitives and the route dispatch seam.
module grid.server.http;

import std.json : JSONValue;
import std.string : split;

/// An inbound HTTP request as seen by the grid router.
struct Request
{
    /// The HTTP method, uppercase ("GET", "POST", "DELETE").
    string method;
    /// The request path without query string.
    string path;
    /// Path parameters extracted by the router, keyed by parameter name.
    string[string] params;
    /// Query parameters parsed from the request line.
    string[string] query;
    /// Request headers keyed by lower-cased name.
    string[string] headers;
    /// Raw request content.
    ubyte[] content;
}

/// An outbound HTTP response built by a route handler.
struct Response
{
    /// HTTP status code.
    ushort status;
    /// HTTP reason phrase.
    string reason;
    /// Response headers keyed by lower-cased name.
    string[string] headers;
    /// Raw response content.
    ubyte[] content;

    /// A 200 response carrying a JSON value as-is.
    static Response ok(JSONValue json)
        => withJson(200, "OK", json);

    /// A 200 response wrapping a value in the W3C `{"value": ...}` envelope.
    static Response okValue(JSONValue value)
    {
        JSONValue json = JSONValue.emptyObject;
        json["value"] = value;
        return ok(json);
    }

    /// A 204 response with no content.
    static Response noContent()
    {
        Response ret;
        ret.status = 204;
        ret.reason = "No Content";
        return ret;
    }

    /// A response with the given status carrying a JSON value.
    static Response withJson(ushort status, string reason, JSONValue json)
    {
        Response ret;
        ret.status = status;
        ret.reason = reason;
        ret.headers["content-type"] = "application/json";
        ret.content = cast(ubyte[])json.toString().dup;
        return ret;
    }

    /// A JSON error response using the W3C `{"value": {"error", "message"}}` envelope.
    static Response error(ushort status, string reason, string errorCode, string message)
    {
        JSONValue value = JSONValue.emptyObject;
        value["error"] = JSONValue(errorCode);
        value["message"] = JSONValue(message);

        JSONValue json = JSONValue.emptyObject;
        json["value"] = value;
        return withJson(status, reason, json);
    }
}

/// A route handler invoked when a request matches a registered route.
alias Handler = Response delegate(Request request);

/// A minimal method-plus-pattern router with path parameter extraction.
///
/// Patterns use `<name>` segments to capture path parameters into `Request.params`,
/// e.g. `/se/grid/distributor/node/<nodeId>/drain` binds `nodeId`. Matching is
/// segment-wise and case-sensitive. The first registered match wins.
class Router
{
private:
    struct Route
    {
        string method;
        /// Literal segments. Param positions hold null.
        string[] segments;
        /// Parameter names, in order of appearance.
        string[] paramNames;
        Handler handler;
    }

    Route[] routes;

public:
    /**
     * Registers a handler for a method and path pattern.
     *
     * Params:
     *  method = The HTTP method, uppercase.
     *  pattern = The path pattern with optional `<name>` parameter segments.
     *  handler = The delegate invoked on a matching request.
     */
    void add(string method, string pattern, Handler handler)
    {
        Route route;
        route.method = method;
        route.handler = handler;

        foreach (segment; pattern.split("/"))
        {
            if (segment.length == 0)
                continue;

            if (segment[0] == '<' && segment[$-1] == '>')
            {
                route.paramNames ~= segment[1..$-1];
                route.segments ~= null;
            }
            else
                route.segments ~= segment;
        }

        routes ~= route;
    }

    /**
     * Dispatches a request to the first matching route.
     *
     * Path parameters are extracted into a copy of the request before the handler
     * runs, so the caller's `request` is not mutated.
     *
     * Params:
     *  request = The inbound request.
     *
     * Returns:
     *  The handler response, or a 404 error response when no route matches.
     */
    Response dispatch(Request request)
    {
        string[] requestSegments = splitSegments(request.path);
        foreach (route; routes)
        {
            if (route.method != request.method)
                continue;

            if (route.segments.length != requestSegments.length)
                continue;

            string[string] params;
            bool match = true;
            size_t paramIdx;
            foreach (i; 0..route.segments.length)
            {
                if (route.segments[i] is null)
                {
                    params[route.paramNames[paramIdx]] = requestSegments[i];
                    paramIdx++;
                }
                else if (route.segments[i] != requestSegments[i])
                {
                    match = false;
                    break;
                }
            }

            if (!match)
                continue;

            Request bound = request;
            bound.params = params;
            return route.handler(bound);
        }
        return Response.error(
            404,
            "Not Found",
            "unknown command",
            "No route for "~request.method~" "~request.path,
        );
    }
}

private:

/// Splits a path into non-empty segments, dropping leading and trailing slashes.
string[] splitSegments(string path)
{
    string[] ret;
    foreach (segment; path.split("/"))
    {
        if (segment.length > 0)
            ret ~= segment;
    }
    return ret;
}
