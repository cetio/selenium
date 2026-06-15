module selenium.logger;

public import std.logger : LogLevel;

import selenium.driver : Driver;

import std.json : JSONValue, JSONType;
import std.net.curl : HTTP;

string toWebDriverLevel(LogLevel level)
{
    switch (level)
    {
        case LogLevel.off:
            return "OFF";
        case LogLevel.error:
            return "SEVERE";
        case LogLevel.warning:
            return "WARNING";
        case LogLevel.info:
            return "INFO";
        case LogLevel.trace:
            return "DEBUG";
        case LogLevel.all:
            return "ALL";
        default:
            return "SEVERE";
    }
}

LogLevel fromWebDriverLevel(string level)
{
    switch (level)
    {
        case "OFF":
            return LogLevel.off;
        case "SEVERE":
            return LogLevel.error;
        case "WARNING":
            return LogLevel.warning;
        case "INFO":
            return LogLevel.info;
        case "DEBUG":
            return LogLevel.trace;
        case "ALL":
            return LogLevel.all;
        default:
            return LogLevel.off;
    }
}

enum LogType : string
{
    Browser = "browser",
    Driver = "driver",
    Client = "client",
    Server = "server",
    Performance = "performance"
}

struct LogEntry
{
    long timestamp;
    LogLevel level;
    string message;

    static LogEntry fromJSON(JSONValue json)
    {
        LogEntry ret;
        if ("timestamp" in json && json["timestamp"].type == JSONType.integer)
            ret.timestamp = json["timestamp"].integer;
        if ("level" in json && json["level"].type == JSONType.string)
            ret.level = fromWebDriverLevel(json["level"].str);
        if ("message" in json && json["message"].type == JSONType.string)
            ret.message = json["message"].str;
        return ret;
    }
}

class Logger
{
package(selenium):
    Driver driver;

private:
    LogEntry[] _entries;

package(selenium):
    void add(LogEntry entry)
    {
        _entries ~= entry;
    }

public:
    LogEntry[] entries()
        => _entries;

    LogLevel[string] levels;
    string path;
    LogLevel driverLevel = LogLevel.off;
    bool append;
    bool readableTimestamp;
    bool silent;

    JSONValue toCapabilities() const
    {
        JSONValue ret = JSONValue.emptyObject;
        foreach (type, level; levels)
            ret[type] = JSONValue(toWebDriverLevel(level));
        return ret;
    }

    string[] toDriverArgs() const
    {
        string[] ret;
        if (path != null)
            ret ~= "--log-path="~path;
        if (driverLevel != LogLevel.off)
            ret ~= "--log-level="~toWebDriverLevel(driverLevel);
        if (append)
            ret ~= "--append-log";
        if (readableTimestamp)
            ret ~= "--readable-timestamp";
        if (silent)
            ret ~= "--silent";
        return ret;
    }

    string[] types()
    {
        JSONValue resp = driver.bridge.request(driver.id, HTTP.Method.get, "/log/types");
        JSONValue value = ("value" in resp) ? resp["value"] : resp;
        string[] ret;
        if (value.type == JSONType.array)
        {
            foreach (item; value.array)
            {
                if (item.type == JSONType.string)
                    ret ~= item.str;
            }
        }
        return ret;
    }

    LogEntry[] fetch(string type)
    {
        JSONValue resp = driver.bridge.request(driver.id, HTTP.Method.post, "/log", ["type": type]);
        JSONValue value = ("value" in resp) ? resp["value"] : resp;
        LogEntry[] ret;
        if (value.type == JSONType.array)
        {
            foreach (entry; value.array)
                ret ~= LogEntry.fromJSON(entry);
        }
        return ret;
    }

    LogEntry[] fetch(LogType type)
        => fetch(cast(string)type);

    LogEntry[] drain(LogType type = LogType.Browser)
    {
        LogEntry[] ret = fetch(cast(string)type);
        foreach (entry; ret)
            add(entry);
        return ret;
    }
}
