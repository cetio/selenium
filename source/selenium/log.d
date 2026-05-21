module selenium.log;

import std.datetime : SysTime, unixTimeToStdTime;
import std.json : JSONType, JSONValue;

enum LogType
{
    None = 0,
    Client = 1 << 0,
    Browser = 1 << 1,
    Driver = 1 << 2,
    Performance = 1 << 3,
    Server = 1 << 4
}

string wireName(LogType type)
{
    final switch (type)
    {
        case LogType.None:
            return null;
        case LogType.Client:
            return "client";
        case LogType.Browser:
            return "browser";
        case LogType.Driver:
            return "driver";
        case LogType.Performance:
            return "performance";
        case LogType.Server:
            return "server";
    }
}

struct LogEntry
{
    string level;
    string message;
    SysTime timestamp;

    static LogEntry fromJSON(JSONValue json)
    {
        LogEntry ret;
        if (json.type != JSONType.object)
            return ret;

        if ("level" in json && json["level"].type == JSONType.string)
            ret.level = json["level"].str;
        if ("message" in json && json["message"].type == JSONType.string)
            ret.message = json["message"].str;
        if ("timestamp" in json)
        {
            JSONValue ts = json["timestamp"];
            long ms;
            if (ts.type == JSONType.integer)
                ms = ts.get!long;
            else if (ts.type == JSONType.uinteger)
                ms = cast(long)ts.get!ulong;
            else if (ts.type == JSONType.float_)
                ms = cast(long)ts.get!double;
            ret.timestamp = SysTime(unixTimeToStdTime(ms / 1000) + (ms % 1000) * 10_000);
        }

        return ret;
    }
}
