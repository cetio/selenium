/// The WebDriver server connection that owns one or more sessions.
module selenium.bridge;

import selenium.browser : Browser;
import selenium.exception;

import conductor.http : Response, send;
import conductor.serialize.json : fromJSON;

import std.json : JSONType, JSONValue, parseJSON;
import std.conv : to;
import std.net.curl : HTTP;
import std.process : kill, Pid, spawnProcess;
import std.socket;
import core.thread : Thread;
import core.time : MonoTime, msecs, Duration;

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
            request(id, HTTP.Method.post, "/timeouts", data);
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
        stop();
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

        HTTP http = HTTP();
        Response response = send(http, HTTP.Method.post, address~"/session", payload);
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
            request(id, HTTP.Method.del, "");
        catch (Exception) { }
        sessions.remove(id);
    }

    /// Kills a locally spawned process and clears all session state.
    void stop()
    {
        if (pid !is Pid.init)
        {
            tryKill(pid);
            pid = Pid.init;
        }
        sessions = null;
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
        HTTP http = HTTP();
        Response response = send(http, HTTP.Method.get, address~"/status");
        return checkAndParse(response);
    }

    /**
     * Issues a parameterless command against a session and parses the result.
     *
     * A POST without a body is redirected to send an empty JSON object. W3C
     * requires a JSON body on POST, and modern drivers reject a missing body with
     * "missing command parameters", so this keeps parameterless POSTs compliant.
     *
     * Params:
     *  id = The target session id.
     *  method = The HTTP method.
     *  path = The session-relative endpoint path.
     *
     * Returns:
     *  The parsed result as T, or the raw JSONValue when T is JSONValue.
     */
    T request(T = JSONValue)(string id, HTTP.Method method, string path)
    {
        if (method == HTTP.Method.post)
            return request!T(id, method, path, JSONValue.emptyObject);

        HTTP http = HTTP();
        Response response = send(http, method, address~"/session/"~id~path);
        JSONValue json = checkAndParse(response);

        static if (is(T == JSONValue))
            return json;
        else static if (!is(T == void))
            return unwrapAndParse!T(json);
    }

    /**
     * Issues a command with a request body against a session and parses the result.
     *
     * Params:
     *  id = The target session id.
     *  method = The HTTP method.
     *  path = The session-relative endpoint path.
     *  data = The request body, serialized to JSON.
     *
     * Returns:
     *  The parsed result as T, or the raw JSONValue when T is JSONValue.
     */
    T request(T = JSONValue, D)(string id, HTTP.Method method, string path, D data)
    {
        HTTP http = HTTP();
        Response response = send(http, method, address~"/session/"~id~path, data);
        JSONValue json = checkAndParse(response);

        static if (is(T == JSONValue))
            return json;
        else static if (!is(T == void))
            return unwrapAndParse!T(json);
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
        if ("value" in json)
            return fromJSON!T(json["value"]);

        return fromJSON!T(json);
    }

private:
    /// Parses a response body and converts an HTTP error status into an exception.
    static JSONValue checkAndParse(Response response)
    {
        if (response.content.length == 0)
            return JSONValue.emptyObject;

        JSONValue ret;
        try
            ret = parseJSON(cast(string)response.content);
        catch (Exception)
        {
            if (response.status >= 200 && response.status < 300)
                return JSONValue.emptyObject;

            throw new WebDriverConnectionException("Invalid response from server:"~cast(string)response.content);
        }

        if (response.status >= 400)
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
                HTTP http = HTTP();
                Response response = send(http, HTTP.Method.get, address~"/status");
                if (response.status == 200)
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
