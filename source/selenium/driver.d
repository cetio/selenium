module selenium.driver;

import selenium.bridge : Bridge;
import selenium.element : Element;
import selenium.error : WebDriverConnectionError;
import selenium.log : LogEntry, LogType, wireName;
import selenium.types;

import std.algorithm.searching : canFind;
import std.conv : to;
import std.json : JSONType, JSONValue;
import std.net.curl : HTTP;
import std.stdio : File, stderr, stdout;
import std.typecons : Tuple;
import std.string : strip;
import core.time : Duration;
static import std.process;

class Driver
{
public:
    Bridge bridge;
    Options options;
    LogEntry[][LogType] entries;
    //File[LogType] destination;

    ref Duration implicitWait() => bridge.implicitWait;

    static Driver start(
        DriverType type = DriverType.Any,
        string executablePath = null,
        Options options = Options.init,
    )
    {
        if (executablePath is null)
            executablePath = autoDetectExecutable(type);
        if (type == DriverType.Any)
            type = inferTypeFromExecutable(executablePath);

        Driver ret = new Driver();
        ret.options = options;
        //ret.destination[LogType.Browser] = stdout;
        //ret.destination[LogType.Driver] = stderr;
        ret.bridge = new Bridge(type, executablePath);
        ret.bridge.launch();
        try
            ret.bridge.init(options);
        catch (Exception)
        {
            ret.bridge.stop();
            throw;
        }
        return ret;
    }

    void fetchLogs()
    {
        if (bridge is null || !bridge.running || options.logTypes == LogType.None)
            return;

        foreach (type; [LogType.Browser, LogType.Driver, LogType.Performance])
        {
            if (!(options.logTypes & type))
                continue;

            JSONValue resp;
            try
                resp = bridge.request(HTTP.Method.post, "/log", ["type": wireName(type)]);
            catch (Exception)
                continue;

            JSONValue value = ("value" in resp) ? resp["value"] : resp;
            if (value.type != JSONType.array)
                continue;

            foreach (item; value.array)
            {
                LogEntry entry = LogEntry.fromJSON(item);
                entries[type] ~= entry;

                // TODO: This is terrible and we should not sink all at once.
                // if (File* sink = type in destination)
                //     sink.writeln("["~wireName(type)~"]["~entry.level~"] "~entry.message);
            }
        }
    }

    void quit()
    {
        if (bridge is null)
            return;

        bridge.disconnect();
        bridge.stop();
    }

    void stop()
    {
        if (bridge !is null)
            bridge.stop();
    }

    string url()
        => bridge.request!string(HTTP.Method.get, "/url");

    void navigate(string url)
    {
        bridge.request(HTTP.Method.post, "/url", ["url": url]);
    }

    void back()
    {
        bridge.request(HTTP.Method.post, "/back");
    }

    void forward()
    {
        bridge.request(HTTP.Method.post, "/forward");
    }

    void refresh()
    {
        bridge.request(HTTP.Method.post, "/refresh");
    }

    string title()
        => bridge.request!string(HTTP.Method.get, "/title");

    string source()
        => bridge.request!string(HTTP.Method.get, "/source");

    string windowHandle()
        => bridge.request!string(HTTP.Method.get, "/window");

    void window(string handle)
    {
        bridge.request(HTTP.Method.post, "/window", ["handle": handle]);
    }

    string[] windowHandles()
        => bridge.handles();

    void closeWindow()
    {
        bridge.request(HTTP.Method.del, "/window");
    }

    void maximize()
    {
        bridge.request(HTTP.Method.post, "/window/maximize");
    }

    Size windowSize()
        => bridge.request!Size(HTTP.Method.get, "/window/rect");

    void windowSize(Size value)
    {
        bridge.request(HTTP.Method.post, "/window/rect", value);
    }

    void frame(string id)
    {
        bridge.request(HTTP.Method.post, "/frame", ["id": id]);
    }

    void frame(long id)
    {
        bridge.request(HTTP.Method.post, "/frame", ["id": id]);
    }

    Element find(Locator strategy, string value)
    {
        bridge.ensureImplicitWaitSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = bridge.request(HTTP.Method.post, "/element", body_);
        return new Element(bridge, Bridge.parseElementId(resp));
    }

    Element[] findAll(Locator strategy, string value)
    {
        bridge.ensureImplicitWaitSynced();

        JSONValue body_ = JSONValue.emptyObject;
        body_["using"] = cast(string)strategy;
        body_["value"] = value;
        JSONValue resp = bridge.request(HTTP.Method.post, "/elements", body_);
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(bridge, eid);
        return ret;
    }

    Element activeElement()
        => new Element(bridge, Bridge.parseElementId(bridge.request(HTTP.Method.get, "/element/active")));

    T execute(T = string)(string script, JSONValue args = JSONValue.emptyArray)
    {
        return bridge.request!T(HTTP.Method.post, "/execute/sync", [
            "script": JSONValue(script),
            "args": args,
        ]);
    }

    string screenshot()
        => bridge.request!string(HTTP.Method.get, "/screenshot");

private:
    this() { }

    static string autoDetectExecutable(DriverType type = DriverType.Any)
    {
        string[] candidates;
        switch (type)
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
            default:
                candidates = [
                    "chromedriver",
                    "msedgedriver",
                    "safaridriver",
                    "geckodriver"
                ];
                break;
        }

        foreach (candidate; candidates)
        {
            Tuple!(int, "status", string, "output") result = std.process.execute(["which", candidate]);
            if (result.status == 0)
                return result.output.strip;
        }

        throw new WebDriverConnectionError(
            "Could not auto-detect executable for "~type.to!string
        );
    }

    static DriverType inferTypeFromExecutable(string path)
    {
        if (path.canFind("chromedriver"))
            return DriverType.Chrome;
        if (path.canFind("geckodriver"))
            return DriverType.Firefox;
        if (path.canFind("msedgedriver") || path.canFind("edgedriver"))
            return DriverType.Edge;
        if (path.canFind("safaridriver"))
            return DriverType.Safari;

        return DriverType.Chrome;
    }
}
