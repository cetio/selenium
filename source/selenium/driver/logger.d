/// Client, driver-process, and remote logging aggregated for a session.
module selenium.driver.logger;

public import std.logger : LogLevel;

import selenium.driver : Driver;

import std.json : JSONValue, JSONType;
import std.net.curl : HTTP;

/// Maps a std.logger level to its WebDriver level string, defaulting to "SEVERE".
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

/// Maps a WebDriver level string to a std.logger level, defaulting to off.
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

/// The categories of remote log a driver may expose.
enum LogType : string
{
    /// Console and page-level browser logs.
    Browser = "browser",
    /// Logs from the driver implementation.
    Driver = "driver",
    /// Logs from the client side of the connection.
    Client = "client",
    /// Logs from the server side of the connection.
    Server = "server",
    /// Performance and timing logs.
    Performance = "performance"
}

/// A single remote log record.
struct LogEntry
{
    /// Unix timestamp in milliseconds.
    long timestamp;
    /// Severity, mapped from the WebDriver level string.
    LogLevel level;
    /// The log message text.
    string message;

    /// Parses an entry from a remote log array element.
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

/// Aggregates every logging concern for a session.
///
/// This type is not part of W3C. It presents a single logging surface even though
/// it spans three separate mechanisms: client-side level mapping, driver-process
/// command-line flags, and remote log retrieval. Per-browser logging preferences
/// are folded upward into one logger when a session starts, because `Driver.start`
/// calls `Browser.normalizeLogger` for each browser so their `levels` accumulate here.
///
/// The capability and endpoint forms are vendor surfaces rather than W3C. The
/// `goog:loggingPrefs` capability is a Chromium extension shared by Chrome and Edge,
/// and the `/log` and `/log/types` endpoints are legacy commands the W3C spec dropped.
class Logger
{
package(selenium):
    /// The session whose remote logs are fetched.
    Driver driver;

private:
    /// Drained remote entries retained for later inspection.
    LogEntry[] _entries;

package(selenium):
    /// Appends a drained entry to the retained buffer.
    void add(LogEntry entry)
    {
        _entries ~= entry;
    }

public:
    /// The remote log entries drained so far.
    LogEntry[] entries()
        => _entries;

    /// Remote log levels per log type, accumulated from each browser's preferences.
    LogLevel[string] levels;
    /// Driver-process log file path, passed as a command-line flag.
    string path;
    /// Driver-process verbosity, passed as a command-line flag.
    LogLevel driverLevel = LogLevel.off;
    /// Append to the driver log file rather than truncating it.
    bool append;
    /// Emit human-readable timestamps in the driver log.
    bool readableTimestamp;
    /// Suppress driver-process logging entirely.
    bool silent;

    /// Serializes `levels` into the `goog:loggingPrefs` capability object.
    JSONValue toCapabilities() const
    {
        JSONValue ret = JSONValue.emptyObject;
        foreach (type, level; levels)
            ret[type] = JSONValue(toWebDriverLevel(level));
        return ret;
    }

    /// Builds the driver-process command-line flags from the configured fields.
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

    /// Queries the log types the driver exposes via the legacy `/log/types` command.
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

    /**
     * Fetches and clears the pending remote logs of a type.
     *
     * Uses the legacy `/log` command, which returns and drains the buffer server side.
     *
     * Params:
     *  type = The log type name.
     *
     * Returns:
     *  The pending entries for the type.
     */
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

    /// Fetches pending remote logs for a typed log category.
    LogEntry[] fetch(LogType type)
        => fetch(cast(string)type);

    /**
     * Fetches a log type and retains its entries on this logger.
     *
     * Params:
     *  type = The log type to drain, defaulting to browser logs.
     *
     * Returns:
     *  The fetched entries, which are also appended to `entries`.
     */
    LogEntry[] drain(LogType type = LogType.Browser)
    {
        LogEntry[] ret = fetch(cast(string)type);
        foreach (entry; ret)
            add(entry);
        return ret;
    }
}
