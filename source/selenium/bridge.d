module selenium.bridge;

import selenium.browser : Browser, Timeouts;
import selenium.error;

import conductor.http : Response, send;
import conductor.serialize.json : fromJSON;

import core.time : Duration;
import std.json : JSONType, JSONValue, parseJSON;
import std.conv : to;
import std.net.curl : HTTP;
import std.process : kill, Pid, spawnProcess;
import std.socket;
import std.string : strip;
import std.typecons : Tuple;
static import std.process;

import core.thread : Thread;
import core.time : MonoTime, msecs;

class Bridge
{
    string address;
    Pid pid;
    string sessionPrefix;
    Timeouts timeouts;

    static Bridge start(string executable)
    {
        Bridge ret = new Bridge();
        if (executable is null)
            executable = findExecutable("chromedriver");

        ushort port = findFreePort();
        ret.pid = spawnProcess([executable, "--port="~port.to!string]);
        ret.address = "http://127.0.0.1:"~port.to!string;
        ret.waitForServer(5000);
        return ret;
    }

    static Bridge connect(string address)
    {
        Bridge ret = new Bridge();
        ret.address = address;
        return ret;
    }

    string createSession(JSONValue payload)
    {
        HTTP http = HTTP();
        Response response = send(http, HTTP.Method.post, address~"/session", payload);
        JSONValue json = checkAndParse(response);

        string sessionId;
        if ("sessionId" in json)
            sessionId = json["sessionId"].str;
        else if ("value" in json && "sessionId" in json["value"])
            sessionId = json["value"]["sessionId"].str;

        sessionPrefix = address~"/session/"~sessionId;
        return sessionId;
    }

    void stop()
    {
        try
            request(HTTP.Method.del, "");
        catch (Exception) { }
        if (pid !is Pid.init)
        {
            tryKill(pid);
            pid = Pid.init;
        }
    }

    T request(T = JSONValue)(HTTP.Method method, string path)
    {
        if (method == HTTP.Method.post)
            return request!T(method, path, JSONValue.emptyObject);

        HTTP http = HTTP();
        Response response = send(http, method, sessionPrefix~path);
        JSONValue json = checkAndParse(response);
        static if (is(T == JSONValue))
            return json;
        else
            return parse!T(json);
    }

    T request(T = JSONValue, B)(HTTP.Method method, string path, B body_)
    {
        HTTP http = HTTP();
        Response response = send(http, method, sessionPrefix~path, body_);
        JSONValue json = checkAndParse(response);
        static if (is(T == JSONValue))
            return json;
        else
            return parse!T(json);
    }

    static string parseElementId(JSONValue json)
    {
        enum W3C_KEY = "element-6066-11e4-a52e-4f735466cecf";
        JSONValue value = ("value" in json) ? json["value"] : json;

        if (value.type == JSONType.object)
        {
            if (W3C_KEY in value && value[W3C_KEY].type == JSONType.string)
                return value[W3C_KEY].str;
            if ("ELEMENT" in value && value["ELEMENT"].type == JSONType.string)
                return value["ELEMENT"].str;
        }

        return null;
    }

    static string[] parseElementIds(JSONValue json)
    {
        JSONValue value = ("value" in json) ? json["value"] : json;
        string[] ret;

        if (value.type == JSONType.array)
        {
            foreach (item; value.array)
                ret ~= parseElementId(item);
        }

        return ret;
    }

package:
    void getTimeouts()
    {
        JSONValue json = request(HTTP.Method.get, "/timeouts");
        JSONValue value = ("value" in json) ? json["value"] : json;

        if (value.type == JSONType.object)
        {
            if ("implicit" in value && value["implicit"].type == JSONType.integer)
                timeouts.implicit = value["implicit"].get!long.msecs;
            if ("pageLoad" in value && value["pageLoad"].type == JSONType.integer)
                timeouts.pageLoad = value["pageLoad"].get!long.msecs;
            if ("script" in value && value["script"].type == JSONType.integer)
                timeouts.script = value["script"].get!long.msecs;
        }
    }

    void ensureTimeoutsSynced()
    {
        static int syncedImplicit;
        static int syncedPage;
        static int syncedScript;

        int implicitTimeout = cast(int)timeouts.implicit.total!"msecs";
        int pageTimeout = cast(int)timeouts.pageLoad.total!"msecs";
        int scriptTimeout = cast(int)timeouts.script.total!"msecs";

        if (implicitTimeout == syncedImplicit && pageTimeout == syncedPage && scriptTimeout == syncedScript)
            return;

        JSONValue body_ = JSONValue.emptyObject;
        if (implicitTimeout != 0)
            body_["implicit"] = JSONValue(implicitTimeout);
        if (pageTimeout != 0)
            body_["pageLoad"] = JSONValue(pageTimeout);
        if (scriptTimeout != 0)
            body_["script"] = JSONValue(scriptTimeout);
        try
        {
            request(HTTP.Method.post, "/timeouts", body_);
            syncedImplicit = implicitTimeout;
            syncedPage = pageTimeout;
            syncedScript = scriptTimeout;
        }
        catch (Exception) { }
    }

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

            throw new WebDriverError("Invalid response from server:"~cast(string)response.content);
        }

        if (response.status >= 400)
            throw mapError(response.status, ret);

        return ret;
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

private:
    static string findExecutable(string candidate)
    {
        Tuple!(int, "status", string, "output") result =
            std.process.execute(["which", candidate]);
        if (result.status == 0)
            return result.output.strip;
        return null;
    }

    static ushort findFreePort()
    {
        Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM);
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
        socket.bind(new InternetAddress("127.0.0.1", 0));
        ushort ret = (cast(InternetAddress)socket.localAddress).port;
        socket.close();
        return ret;
    }

    void waitForServer(long timeoutMs)
    {
        import std.conv : to;

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

        throw new WebDriverError(
            "WebDriver did not become ready within "~timeoutMs.to!string~" ms"
        );
    }

    static void tryKill(Pid process)
    {
        try
            kill(process);
        catch (Exception) { }
    }

    static T parse(T)(JSONValue json)
    {
        if ("value" in json)
            return fromJSON!T(json["value"]);

        return fromJSON!T(json);
    }
}
