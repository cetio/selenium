module selenium.browser;

import selenium.error : WebDriverError;
import conductor.http : Response, send;

import std.json : JSONValue;
import std.net.curl : HTTP;
import std.process : kill, Pid, spawnProcess;
import std.socket;
import std.string : strip;
import std.typecons : Tuple;
static import std.process;

import core.thread : Thread;
import core.time : Duration, MonoTime, msecs;

enum PageLoadStrategy : string
{
    Normal = "normal",
    Eager = "eager",
    None = "none"
}

enum UnhandledPromptBehavior : string
{
    Dismiss = "dismiss",
    Accept = "accept",
    DismissAndNotify = "dismiss and notify",
    AcceptAndNotify = "accept and notify",
    Ignore = "ignore"
}

struct Timeouts
{
    /// Time to wait for an element to exist when locating.
    Duration implicit;
    /// Time to wait for page navigation to complete.
    Duration pageLoad;
    /// Time to wait for script evaluation to complete.
    Duration script;
}

class Browser
{
private:
    string _executablePath;

package (selenium):
    Pid pid;
    ushort port;
    string serverUrl;
    
public:
    /// Accept insecure TLS certificates.
    bool acceptInsecureCerts;
    /// Page load readiness strategy.
    PageLoadStrategy pageLoadStrategy;
    /// Support window resizing and positioning.
    bool setWindowRect;
    /// Enforce file input interactability checks.
    bool strictFileInteractability;
    /// Strategy for user prompts not handled by commands.
    UnhandledPromptBehavior unhandledPromptBehavior;
    /// Session timeout configuration.
    Timeouts timeouts;

    string name() const
        => "";

    bool generic() const
        => name.length == 0;

    ref string executablePath()
    {
        if (_executablePath == null)
        {
            foreach (candidate; ["chromedriver", "msedgedriver", "safaridriver", "geckodriver"])
            {
                string path = findExecutable(candidate);
                if (path != null)
                {
                    _executablePath = path;
                    break;
                }
            }
        }
        return _executablePath;
    }

    void start(ushort requestedPort = 0)
    {
        if (pid !is Pid.init)
            return;

        import std.conv : to;

        port = requestedPort == 0 ? findFreePort() : requestedPort;
        pid = spawnProcess([executablePath, "--port="~port.to!string]);
        serverUrl = "http://127.0.0.1:"~port.to!string;
        waitForServer(5000);
    }

    void stop()
    {
        if (pid is Pid.init)
            return;

        tryKill(pid);
        pid = Pid.init;
    }

    JSONValue toJSONValue() const
    {
        JSONValue ret = JSONValue.emptyObject;
        if (name != null)
            ret["browserName"] = JSONValue(name);
        if (acceptInsecureCerts)
            ret["acceptInsecureCerts"] = JSONValue(true);
        if (pageLoadStrategy != PageLoadStrategy.init)
            ret["pageLoadStrategy"] = JSONValue(cast(string)pageLoadStrategy);
        if (setWindowRect)
            ret["setWindowRect"] = JSONValue(true);
        if (strictFileInteractability)
            ret["strictFileInteractability"] = JSONValue(true);
        if (unhandledPromptBehavior != UnhandledPromptBehavior.init)
            ret["unhandledPromptBehavior"] = JSONValue(cast(string)unhandledPromptBehavior);

        JSONValue timeoutsObj = JSONValue.emptyObject;
        if (timeouts.implicit != Duration.init)
            timeoutsObj["implicit"] = JSONValue(cast(int)timeouts.implicit.total!"msecs");
        if (timeouts.pageLoad != Duration.init)
            timeoutsObj["pageLoad"] = JSONValue(cast(int)timeouts.pageLoad.total!"msecs");
        if (timeouts.script != Duration.init)
            timeoutsObj["script"] = JSONValue(cast(int)timeouts.script.total!"msecs");
        if (timeoutsObj.object.length > 0)
            ret["timeouts"] = timeoutsObj;

        return ret;
    }

package:
    static string findExecutable(string candidate)
    {
        Tuple!(int, "status", string, "output") result =
            std.process.execute(["which", candidate]);
        if (result.status == 0)
            return result.output.strip;
        return null;
    }

private:
    ushort findFreePort()
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
                Response response = send(http, HTTP.Method.get, serverUrl~"/status");
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
}
