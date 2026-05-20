module selenium.log;

import std.datetime;

enum LogType
{
    None = 0,
    Client = 1 << 0,
    Browser = 1 << 1,
    Driver = 1 << 2,
    Performance = 1 << 3,
    Server = 1 << 4
}

struct LogEntry
{
    string level;
    string message;
    SysTime timestamp;
}
