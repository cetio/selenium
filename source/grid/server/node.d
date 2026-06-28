/// The grid node: slot host composing WebDriver bridges and node endpoints.
module grid.server.node;

import grid.server.http;
import grid.server.model;

import selenium.browser : Browser;
import selenium.bridge : Bridge;

import std.conv : to;
import std.json : JSONValue;

/// A grid node that hosts WebDriver slots and serves node-level endpoints.
///
/// A Node is the worker analog of `selenium.bridge.Bridge`: where a Bridge owns
/// one WebDriver process, a Node owns several and advertises them as slots to a
/// hub. Each slot maps to a capability stereotype and hosts at most one session.
class Node
{
public:
    /// The node id as registered with the hub, or null to derive from `address`.
    string id;
    /// The base URL the node advertises, e.g. "http://127.0.0.1:5555".
    string address;
    /// The hub URL the node registers with, or null when standalone.
    string hubAddress;
    /// The registration secret shared with the hub, or null for an open grid.
    string secret;
    /// The route table populated with every node endpoint.
    Router router;
    /// The WebDriver bridges backing each slot, populated when live serving begins.
    Bridge[] bridges;
    /// The slots advertised by this node, built from the slot browser stereotypes.
    Slot[] slots;

    /**
     * Configures a node with one slot per browser and registers its route table.
     *
     * The node does not spawn its WebDriver bridges or accept connections until a
     * server loop is attached. Slot stereotypes are derived from each browser's
     * capabilities so the routing surface can be exercised without live drivers.
     *
     * Params:
     *  slotBrowsers = One browser per slot, defining each slot's stereotype.
     *  hubAddress = The hub URL to register with, or null for standalone.
     *  port = The port the node advertises in its address.
     *  secret = The registration secret shared with the hub, or null.
     *
     * Returns:
     *  A configured node with slots and routes registered.
     */
    static Node start(Browser[] slotBrowsers, string hubAddress = null, ushort port = 5555, string secret = null)
    {
        Node ret = new Node();
        ret.address = "http://127.0.0.1:"~port.to!string;
        ret.hubAddress = hubAddress;
        ret.secret = secret;
        ret.router = new Router();
        ret.slots = buildSlots(slotBrowsers);
        ret.registerRoutes();
        return ret;
    }

    /// Stops every bridge and releases the route table and slot state. Idempotent.
    void stop()
    {
        foreach (bridge; bridges)
            bridge.stop();

        bridges = null;
        slots = null;
        router = null;
    }

    /// The local node status, built from the slot table.
    NodeInfo status()
    {
        NodeInfo ret;
        ret.id = id.length > 0 ? id : address;
        ret.uri = address;
        ret.maxSessions = cast(int)slots.length;
        ret.availability = Availability.Up;
        ret.osInfo = JSONValue.emptyObject;
        ret.slots = slots.dup;
        return ret;
    }

package:

    /// Builds one slot per browser from its capability stereotype.
    static Slot[] buildSlots(Browser[] slotBrowsers)
    {
        Slot[] ret;
        foreach (i, browser; slotBrowsers)
        {
            Slot slot;
            slot.id = i.to!string;
            slot.stereotype.capabilities = browser.toJSON();
            ret ~= slot;
        }
        return ret;
    }

    /// Registers every node endpoint on the router.
    void registerRoutes()
    {
        router.add("GET", "/status", &handleStatus);
        router.add("POST", "/se/grid/node/drain", &handleDrain);
        router.add("GET", "/se/grid/node/owner/<sessionId>", &handleOwner);
        router.add("DELETE", "/se/grid/node/session/<sessionId>", &handleDeleteSession);
    }

    Response handleStatus(Request request)
        => Response.okValue(status().toJSON());

    Response handleDrain(Request request)
    {
        if (!checkSecret(request))
            return Response.error(403, "Forbidden", "unknown command", "Invalid registration secret.");

        // Forward-thinking: mark availability draining and reject new sessions
        // once the live server loop is attached.
        return Response.okValue(JSONValue.emptyObject);
    }

    Response handleOwner(Request request)
    {
        if (!checkSecret(request))
            return Response.error(403, "Forbidden", "unknown command", "Invalid registration secret.");

        string sessionId = request.params["sessionId"];
        bool owns;
        foreach (slot; slots)
        {
            if (slot.sessionId == sessionId)
            {
                owns = true;
                break;
            }
        }
        return Response.okValue(JSONValue(owns));
    }

    Response handleDeleteSession(Request request)
    {
        if (!checkSecret(request))
            return Response.error(403, "Forbidden", "unknown command", "Invalid registration secret.");

        string sessionId = request.params["sessionId"];
        foreach (ref slot; slots)
        {
            if (slot.sessionId == sessionId)
            {
                slot.sessionId = null;
                break;
            }
        }
        return Response.okValue(JSONValue.emptyObject);
    }

    /// Validates the registration secret header against the configured secret.
    ///
    /// When no secret is configured, any request is accepted, matching open grid.
    bool checkSecret(Request request)
    {
        if (secret is null)
            return true;

        return "x-registration-secret" in request.headers
            && request.headers["x-registration-secret"] == secret;
    }
}
