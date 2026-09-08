/// The WebDriver server connection that owns one or more sessions.
module selenium.bridge;

import selenium.browser : Browser;
import selenium.exception;

import requests;

import std.json : JSONType, JSONValue, parseJSON;
import std.conv : to;
import std.process : kill, Pid, spawnProcess;
import std.socket;
import core.thread : Thread;
import core.time : MonoTime, msecs, Duration;
import core.stdc.stdio : printf;

/// A connection to a single WebDriver server, whether spawned locally or remote.
///
/// W3C describes commands per session, which makes a driver and a session look
/// like a 1:1 pairing. A Bridge does not follow that assumption. It models the
/// server process itself and can host many concurrent sessions through `sessions`,
/// bounded only by the optional `capacity`. Each `Driver` is a handle to one of
/// those sessions, so several drivers may share a single Bridge.
class Bridge
{
package (selenium):
    /// The capability key identifying a W3C element reference in payloads.
    enum string W3C_KEY = "element-6066-11e4-a52e-4f735466cecf";
    /// The capability key identifying a W3C shadow root reference in payloads.
    enum string SHADOW_KEY = "shadow-6066-11e4-a52e-4f735466cecf";

    /// Last implicit wait pushed to the server, in milliseconds.
    int syncImplicit;
    /// Last page load timeout pushed to the server, in milliseconds.
    int syncPage;
    /// Last script timeout pushed to the server, in milliseconds.
    int syncScript;

    /**
     * Pushes the browser timeout configuration to the session if it has changed.
     *
     * Timeouts are synced lazily so that unchanged values do not incur an extra
     * request before each command. Failures are swallowed so a rejected sync does
     * not abort the caller's command.
     *
     * Params:
     *  id = The target session id.
     *  browser = The browser whose timeout configuration to apply.
     */
    void ensureTimeoutsSynced(string id, Browser browser)
    {
        int implicitTimeout = cast(int)browser.timeouts.implicit.total!"msecs";
        int pageTimeout = cast(int)browser.timeouts.pageLoad.total!"msecs";
        int scriptTimeout = cast(int)browser.timeouts.script.total!"msecs";

        if (implicitTimeout == syncImplicit && pageTimeout == syncPage && scriptTimeout == syncScript)
            return;

        JSONValue data = JSONValue.emptyObject;
        if (implicitTimeout != 0)
            data["implicit"] = JSONValue(implicitTimeout);
        if (pageTimeout != 0)
            data["pageLoad"] = JSONValue(pageTimeout);
        if (scriptTimeout != 0)
            data["script"] = JSONValue(scriptTimeout);
        try
        {
            post(id, "/timeouts", data);
            syncImplicit = implicitTimeout;
            syncPage = pageTimeout;
            syncScript = scriptTimeout;
        }
        catch (Exception) { }
    }

public:
    /// Base URL of the WebDriver server, e.g. "http://127.0.0.1:9515".
    string address;
    /// Process id of a locally spawned driver.
    Pid pid;
    /// Maximum concurrent sessions, fixed at construction, or 0 for unlimited.
    const int capacity;
    /// Active sessions keyed by session id, mapped to their negotiated browser.
    Browser[string] sessions;

    /**
     * Creates a bridge with the given session capacity.
     *
     * `capacity` is fixed at construction and cannot be changed afterwards. A
     * remote bridge created through `Driver.connect` uses a capacity of 1 so
     * that only the connecting session may use it.
     *
     * Params:
     *  capacity = Maximum concurrent sessions, or 0 for unlimited.
     */
    this(int capacity = 0)
    {
        this.capacity = capacity;
    }

    /// Stops the server and tears down all sessions on collection.
    ~this()
    {
        printf("[bridge] ~this() entered\n");
        stop();
        printf("[bridge] ~this() done\n");
    }
    
    /**
     * Spawns a WebDriver binary on a free port and waits for it to accept requests.
     *
     * Params:
     *  binary = Path to the driver executable.
     *  args = Extra command-line arguments forwarded to the executable.
     *  capacity = Maximum concurrent sessions, or 0 for unlimited.
     *
     * Returns:
     *  A Bridge owning the spawned process.
     *
     * Throws:
     *  InvalidArgumentException if binary is null.
     *  WebDriverConnectionException if the server does not become ready in time.
     */
    static Bridge start(string binary, string[] args = null, int capacity = 0)
    {
        if (binary == null)
            throw new InvalidArgumentException("Valid binary path must be provided.");

        Bridge ret = new Bridge(capacity);
        ushort port = findFreePort();
        ret.pid = spawnProcess([binary, "--port="~port.to!string]~args);
        ret.address = "http://127.0.0.1:"~port.to!string;
        ret.waitForServer(5000);
        return ret;
    }

    /**
     * Creates a new session and records its negotiated browser capabilities.
     *
     * Params:
     *  payload = The new-session capabilities request body.
     *
     * Returns:
     *  The id of the created session.
     *
     * Throws:
     *  WebDriverConnectionException if `capacity` is reached.
     */
    string createSession(JSONValue payload)
    {
        if (capacity > 0 && sessions.length >= capacity)
            throw new WebDriverConnectionException("Bridge capacity exceeded.");

        string str = payload.toString();
        Response response = request(str).post(
            address~"/session",
            str,
            "application/json"
        );
        JSONValue json = checkAndParse(response);

        string id;
        if ("value" in json && "sessionId" in json["value"])
            id = json["value"]["sessionId"].str;

        JSONValue capabilities;
        if ("value" in json && "capabilities" in json["value"])
            capabilities = json["value"]["capabilities"];
        else
            capabilities = JSONValue.emptyObject;

        sessions[id] = Browser.fromJSONValue(capabilities);
        return id;
    }

    /**
     * Ends a single session and removes it from `sessions`.
     *
     * Errors from the delete request are ignored so that a dead session is still
     * dropped locally.
     *
     * Params:
     *  id = The session id to close.
     */
    void closeSession(string id)
    {
        try
            del(id, "");
        catch (Exception) { }
        sessions.remove(id);
    }

    /// Kills a locally spawned process and clears all session state.
    void stop()
    {
        printf("[bridge] stop() entered, pid set=%d\n", pid !is Pid.init);
        if (pid !is Pid.init)
        {
            printf("[bridge] stop() calling tryKill\n");
            tryKill(pid);
            printf("[bridge] stop() tryKill done, clearing pid\n");
            pid = Pid.init;
        }
        printf("[bridge] stop() clearing sessions (length=%zu)\n", sessions.length);
        sessions = null;
        printf("[bridge] stop() done\n");
    }

    /// The server status from `GET /status`, as the raw parsed JSON.
    ///
    /// Any WebDriver server answers `/status` with a `{"value": ...}` envelope.
    /// For a grid hub the value contains node and slot information; for a standalone
    /// driver it contains readiness and a message. The raw JSON is returned so the
    /// caller can parse it into `grid.server.model.GridStatus` or inspect it
    /// directly, keeping `Bridge` decoupled from grid types.
    JSONValue status()
    {
        Request req = Request();
        Response response = req.get(address~"/status");
        return checkAndParse(response);
    }

    /// Issues a GET against a session and parses the result.
    T get(T = JSONValue)(string id, string path)
    {
        Request req = Request();
        return parseResponse!T(req.get(address~"/session/"~id~path));
    }

    /// Issues a parameterless POST against a session, sending an empty JSON object.
    T post(T = JSONValue)(string id, string path)
    {
        return post!T(id, path, JSONValue.emptyObject);
    }

    /// Issues a POST with a JSONValue body against a session and parses the result.
    T post(T = JSONValue)(string id, string path, JSONValue data)
    {
        return post!T(id, path, data.toString(), "application/json");
    }

    /// Issues a POST with a raw string body against a session, without forcing a content type.
    T post(T = JSONValue)(string id, string path, string data)
    {
        return post!T(id, path, data, null);
    }

    /// Issues a POST with a raw string body and optional content type, using Content-Length.
    T post(T = JSONValue)(string id, string path, string data, string contentType)
    {
        return parseResponse!T(request(data).post(address~"/session/"~id~path, data, contentType));
    }

    /// Issues a PUT with a JSONValue body against a session and parses the result.
    T put(T = JSONValue)(string id, string path, JSONValue data)
    {
        string str = data.toString();
        return parseResponse!T(request(str).put(
            address~"/session/"~id~path,
            str,
            "application/json"
        ));
    }

    /// Issues a PATCH with a JSONValue body against a session and parses the result.
    T patch(T = JSONValue)(string id, string path, JSONValue data)
    {
        string str = data.toString();
        return parseResponse!T(request(str).patch(
            address~"/session/"~id~path,
            str,
            "application/json"
        ));
    }

    /// Issues a DELETE against a session and parses the result.
    T del(T = JSONValue)(string id, string path)
    {
        Request req = Request();
        return parseResponse!T(req.deleteRequest(address~"/session/"~id~path));
    }

    /**
     * Extracts a single element reference from a response.
     *
     * Accepts both the W3C key and the legacy "ELEMENT" key so responses from
     * older drivers still resolve.
     *
     * Params:
     *  json = The response value or envelope.
     *
     * Returns:
     *  The element reference, or null if none is present.
     */
    static string parseElementId(JSONValue json)
    {
        JSONValue value = (json.type == JSONType.object && "value" in json) ? json["value"] : json;

        if (value.type == JSONType.object)
        {
            if (W3C_KEY in value && value[W3C_KEY].type == JSONType.string)
                return value[W3C_KEY].str;
            if ("ELEMENT" in value && value["ELEMENT"].type == JSONType.string)
                return value["ELEMENT"].str;
        }

        return null;
    }

    /**
     * Extracts every element reference from an array response.
     *
     * Params:
     *  json = The response value or envelope wrapping an array.
     *
     * Returns:
     *  The element references in order, or an empty array if none are present.
     */
    static string[] parseElementIds(JSONValue json)
    {
        JSONValue value = (json.type == JSONType.object && "value" in json) ? json["value"] : json;
        string[] ret;

        if (value.type == JSONType.array)
        {
            foreach (item; value.array)
                ret ~= parseElementId(item);
        }

        return ret;
    }

    /**
     * Extracts a single shadow root reference from a response.
     *
     * Params:
     *  json = The response value or envelope.
     *
     * Returns:
     *  The shadow root reference, or null if none is present.
     */
    static string parseShadowId(JSONValue json)
    {
        JSONValue value = (json.type == JSONType.object && "value" in json) ? json["value"] : json;

        if (value.type == JSONType.object && SHADOW_KEY in value && value[SHADOW_KEY].type == JSONType.string)
            return value[SHADOW_KEY].str;

        return null;
    }

    /**
     * Extracts every shadow root reference from an array response.
     *
     * Params:
     *  json = The response value or envelope wrapping an array.
     *
     * Returns:
     *  The shadow root references in order, or an empty array if none are present.
     */
    static string[] parseShadowIds(JSONValue json)
    {
        JSONValue value = (json.type == JSONType.object && "value" in json) ? json["value"] : json;
        string[] ret;

        if (value.type == JSONType.array)
        {
            foreach (item; value.array)
                ret ~= parseShadowId(item);
        }

        return ret;
    }

    /// Deserializes T from a response, unwrapping the W3C `value` envelope if present.
    static T unwrapAndParse(T)(JSONValue json)
    {
        JSONValue value = (json.type == JSONType.object && "value" in json) ? json["value"] : json;
        static if (is(T == JSONValue))
            return value;
        else static if (!is(T == string) && is(T == ElementType[], ElementType))
        {
            T ret;
            foreach (item; value.array)
                ret ~= unwrapAndParse!ElementType(item);
            return ret;
        }
        else
            return value.get!T;
    }

private:
    /// Creates a request with a known content length.
    static Request request(string data)
    {
        Request ret = Request();
        ret.addHeaders(["Content-Length": data.length.to!string]);
        return ret;
    }

    /// Parses a response into T, unwrapping the W3C value envelope when T is not JSONValue.
    static T parseResponse(T)(Response response)
    {
        JSONValue json = checkAndParse(response);
        static if (is(T == JSONValue))
            return json;
        else static if (!is(T == void))
            return unwrapAndParse!T(json);
    }

    /// Parses a response body and converts an HTTP error status into an exception.
    static JSONValue checkAndParse(Response response)
    {
        string content = cast(string)response.responseBody.data;
        if (content.length == 0)
            return JSONValue.emptyObject;

        JSONValue ret;
        try
            ret = parseJSON(content);
        catch (Exception)
        {
            if (response.code >= 200 && response.code < 300)
                return JSONValue.emptyObject;

            throw new WebDriverConnectionException("Invalid response from server:"~content);
        }

        if (response.code >= 400)
            throw mapException(ret);

        return ret;
    }

    /// Binds an ephemeral port on the loopback interface and returns it.
    static ushort findFreePort()
    {
        Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM);
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
        socket.bind(new InternetAddress("127.0.0.1", 0));
        ushort ret = (cast(InternetAddress)socket.localAddress).port;
        socket.close();
        return ret;
    }

    /// Polls the server status endpoint until it responds or the timeout elapses.
    void waitForServer(long timeoutMs)
    {
        MonoTime startTime = MonoTime.currTime;
        while ((MonoTime.currTime - startTime).total!"msecs" < timeoutMs)
        {
            try
            {
                Request req = Request();
                Response response = req.get(address~"/status");
                if (response.code == 200)
                    return;
            }
            catch (Exception) { }
            Thread.sleep(100.msecs);
        }

        throw new WebDriverConnectionException(
            "WebDriver did not become ready within "~timeoutMs.to!string~"ms"
        );
    }

    /// Kills a process, ignoring failures from an already dead process.
    static void tryKill(Pid process)
    {
        try
            kill(process);
        catch (Exception) { }
    }
}
