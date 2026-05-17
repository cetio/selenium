module selenium.driver;

import conductor;
import conductor.http : send;
import selenium.api;
import selenium.session;
import std.conv : to;
import std.net.curl : HTTP;
import std.process;
import std.socket;
import std.string;
import core.thread : Thread;
import core.time : MonoTime, msecs, seconds;

enum DriverType
{
    Chrome,
    Firefox,
    Edge,
    Safari
}

class SeleniumDriver
{
private:
    DriverType driverType;
    string executablePath;
    Pid pid;
    string _serverUrl;
    ushort port;
    bool _running;

public:
    this(DriverType type, string path = "")
    {
        driverType = type;
        executablePath = path;
    }

    string serverUrl() const
    {
        return _serverUrl;
    }

    bool isRunning() const
    {
        return _running;
    }

    void start(ushort requestedPort = 0)
    {
        if (_running)
            return;

        port = requestedPort;
        if (port == 0)
            port = findFreePort();

        string[] args;
        args ~= "--port="~port.to!string;

        if (executablePath.length == 0)
            executablePath = autoDetectExecutable();

        pid = spawnProcess([executablePath]~args);
        _serverUrl = "http://127.0.0.1:"~port.to!string;

        waitForServer(5000);
        _running = true;
    }

    void stop()
    {
        if (!_running || pid is Pid.init)
            return;

        tryKill(pid);
        _running = false;
        pid = Pid.init;
    }

    immutable (SeleniumSession) newSession(
        Capabilities desiredCapabilities = Capabilities(),
        Capabilities requiredCapabilities = Capabilities()
    )
    {
        if (!_running)
            throw new Exception("Driver is not running. Call start() first.");

        return new immutable SeleniumSession(_serverUrl,
            desiredCapabilities, requiredCapabilities);
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

    string autoDetectExecutable()
    {
        string[] candidates;
        final switch (driverType)
        {
            case DriverType.Chrome:
                candidates = ["chromedriver"];
                break;
            case DriverType.Firefox:
                candidates = ["geckodriver"];
                break;
            case DriverType.Edge:
                candidates = ["msedgedriver"];
                break;
            case DriverType.Safari:
                candidates = ["safaridriver"];
                break;
        }

        foreach (candidate; candidates)
        {
            if (execute(["which", candidate]).status == 0)
                return execute(["which", candidate]).output.strip;
        }

        throw new Exception("Could not auto-detect executable for "~driverType.to!string);
    }

    void waitForServer(long timeoutMs)
    {
        MonoTime startTime = MonoTime.currTime;

        while ((MonoTime.currTime - startTime).total!"msecs" < timeoutMs)
        {
            try
            {
                HTTP http = HTTP();
                Response response = send(http, HTTP.Method.get, _serverUrl~"/status");
                if (response.status == 200)
                    return;
            }
            catch (Exception)
            {
                // Server not ready yet
            }

            Thread.sleep(100.msecs);
        }

        throw new Exception("WebDriver did not become ready within "~timeoutMs.to!string~" ms");
    }

    static void tryKill(Pid process)
    {
        try
        {
            std.process.kill(process);
            std.process.wait(process);
        }
        catch (Exception)
        {
            // Best-effort cleanup
        }
    }
}

