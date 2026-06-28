/// Grid status, node, slot, and session data models for the wire envelope.
module selenium.grid.server.model;

import std.json : JSONValue, JSONType;

/// Node availability, as reported to the grid.
enum Availability : string
{
    /// The node accepts new sessions.
    Up = "up",
    /// The node is unreachable or has crashed.
    Down = "down",
    /// The node finishes running sessions but accepts no new ones.
    Draining = "draining",
}

/// The capability stereotype advertised for a slot, kept dynamic per browser.
///
/// Capabilities vary per browser and vendor extension, so the stereotype holds
/// the raw capability object rather than a typed mirror of every possible field.
struct Stereotype
{
    /// The raw capability object (`browserName`, `platformName`, vendor keys, ...).
    JSONValue capabilities;

    /// Serializes the stereotype into its bare capability object.
    JSONValue toJSON() const
    {
        if (capabilities.type == JSONType.object)
            return capabilities;

        return JSONValue.emptyObject;
    }

    /// Parses a stereotype from a capability object.
    static Stereotype fromJSON(JSONValue json)
    {
        Stereotype ret;
        ret.capabilities = json;
        return ret;
    }
}

/// A single execution slot on a node, hosting at most one session at a time.
struct Slot
{
    /// The opaque slot id, unique within its node.
    string id;
    /// The capability stereotype this slot serves.
    Stereotype stereotype;
    /// The session id currently occupying this slot, or null when free.
    string sessionId;

    /// Whether the slot is currently hosting a session.
    bool occupied() const
        => sessionId.length > 0;

    /// Serializes the slot, omitting the session reference when free.
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["id"] = JSONValue(id);
        ret["stereotype"] = stereotype.toJSON();
        if (sessionId.length > 0)
            ret["session"] = JSONValue(sessionId);

        return ret;
    }

    /// Parses a slot from a slot object.
    static Slot fromJSON(JSONValue json)
    {
        Slot ret;
        if (json.type != JSONType.object)
            return ret;

        if ("id" in json && json["id"].type == JSONType.string)
            ret.id = json["id"].str;

        if ("stereotype" in json)
            ret.stereotype = Stereotype.fromJSON(json["stereotype"]);

        if ("session" in json && json["session"].type == JSONType.string)
            ret.sessionId = json["session"].str;

        return ret;
    }
}

/// A node's status as reported to the hub, mirroring the Grid `/status` node shape.
struct NodeInfo
{
    /// The node id, unique within the grid.
    string id;
    /// The node URL, e.g. "http://127.0.0.1:5555".
    string uri;
    /// The maximum concurrent sessions the node can host.
    int maxSessions;
    /// Whether the node is up, down, or draining.
    Availability availability;
    /// Raw host OS info (`arch`, `name`, `version`), kept dynamic.
    JSONValue osInfo;
    /// The slots advertised by the node.
    Slot[] slots;

    /// Serializes the node status into its bare object.
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["id"] = JSONValue(id);
        ret["uri"] = JSONValue(uri);
        ret["maxSessions"] = JSONValue(maxSessions);
        ret["availability"] = JSONValue(cast(string)availability);
        if (osInfo.type == JSONType.object)
            ret["osInfo"] = osInfo;

        JSONValue slotsArr = JSONValue.emptyArray;
        foreach (slot; slots)
            slotsArr.array ~= slot.toJSON();

        ret["slots"] = slotsArr;
        return ret;
    }

    /// Parses a node status from a bare object or a `{"value": ...}` envelope.
    static NodeInfo fromJSON(JSONValue json)
    {
        json = unwrap(json);
        NodeInfo ret;
        if (json.type != JSONType.object)
            return ret;

        if ("id" in json && json["id"].type == JSONType.string)
            ret.id = json["id"].str;

        if ("uri" in json && json["uri"].type == JSONType.string)
            ret.uri = json["uri"].str;

        if ("maxSessions" in json && json["maxSessions"].type == JSONType.integer)
            ret.maxSessions = cast(int)json["maxSessions"].integer;

        if ("availability" in json && json["availability"].type == JSONType.string)
            ret.availability = parseAvailability(json["availability"].str);

        if ("osInfo" in json)
            ret.osInfo = json["osInfo"];

        if ("slots" in json && json["slots"].type == JSONType.array)
        {
            foreach (item; json["slots"].array)
                ret.slots ~= Slot.fromJSON(item);
        }
        return ret;
    }
}

/// The grid-level status envelope returned by `/status`.
struct GridStatus
{
    /// Whether the grid has at least one node ready to serve sessions.
    bool ready;
    /// A human-readable readiness message.
    string message;
    /// The status of every registered node.
    NodeInfo[] nodes;

    /// Serializes the grid status into its bare object.
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["ready"] = JSONValue(ready);
        if (message.length > 0)
            ret["message"] = JSONValue(message);

        JSONValue nodesArr = JSONValue.emptyArray;
        foreach (node; nodes)
            nodesArr.array ~= node.toJSON();

        ret["nodes"] = nodesArr;
        return ret;
    }

    /// Parses a grid status from a bare object or a `{"value": ...}` envelope.
    static GridStatus fromJSON(JSONValue json)
    {
        json = unwrap(json);
        GridStatus ret;
        if (json.type != JSONType.object)
            return ret;

        if ("ready" in json)
            ret.ready = json["ready"].type == JSONType.true_;

        if ("message" in json && json["message"].type == JSONType.string)
            ret.message = json["message"].str;

        if ("nodes" in json && json["nodes"].type == JSONType.array)
        {
            foreach (item; json["nodes"].array)
                ret.nodes ~= NodeInfo.fromJSON(item);
        }
        return ret;
    }
}

/// A session tracked by the hub, mapped to its owning node.
struct SessionInfo
{
    /// The W3C session id.
    string id;
    /// The node id hosting this session.
    string nodeId;
    /// The negotiated session capabilities, kept dynamic.
    JSONValue capabilities;

    /// Serializes the session into its bare object.
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["id"] = JSONValue(id);
        ret["nodeId"] = JSONValue(nodeId);
        if (capabilities.type == JSONType.object)
            ret["capabilities"] = capabilities;

        return ret;
    }

    /// Parses a session from a bare object or a `{"value": ...}` envelope.
    static SessionInfo fromJSON(JSONValue json)
    {
        json = unwrap(json);
        SessionInfo ret;
        if (json.type != JSONType.object)
            return ret;

        if ("id" in json && json["id"].type == JSONType.string)
            ret.id = json["id"].str;

        if ("nodeId" in json && json["nodeId"].type == JSONType.string)
            ret.nodeId = json["nodeId"].str;

        if ("capabilities" in json)
            ret.capabilities = json["capabilities"];

        return ret;
    }
}

private:

/// Unwraps a `{"value": ...}` envelope, returning the inner value when present.
JSONValue unwrap(JSONValue json)
{
    if (json.type == JSONType.object && "value" in json)
        return json["value"];

    return json;
}

/// Maps a wire availability string to its enum, defaulting to `Up`.
Availability parseAvailability(string value)
{
    switch (value)
    {
        case "down":
            return Availability.Down;
        case "draining":
            return Availability.Draining;
        default:
            return Availability.Up;
    }
}
