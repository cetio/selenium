/// The grid hub: request router, node registry, and session ownership map.
module selenium.grid.server.hub;

import selenium.grid.server.http;
import selenium.grid.server.model;

import std.conv : to;
import std.json : JSONValue;

/// The grid entry point that routes requests and tracks the node registry.
///
/// A Hub is the coordinator analog of `selenium.bridge.Bridge`: where a Bridge
/// owns WebDriver sessions on one process, a Hub owns node registrations across
/// many processes. It does not host WebDriver sessions itself. It forwards new
/// session requests to a matching node and tracks which node owns each session.
class Hub
{
public:
    /// The base URL the hub advertises, e.g. "http://127.0.0.1:4444".
    string address;
    /// The registration secret required by secured grid endpoints, or null.
    string secret;
    /// The route table populated with every grid endpoint.
    Router router;
    /// Registered nodes keyed by node id, mapped to their last reported status.
    NodeInfo[string] nodes;
    /// Active sessions keyed by session id, mapped to their owning node.
    SessionInfo[string] sessions;

    /**
     * Configures a hub on the given port and registers its route table.
     *
     * The hub does not accept connections until a server loop is attached. This
     * keeps configuration independent from the transport so the routing surface
     * can be exercised and tested without sockets.
     *
     * Params:
     *  port = The port the hub advertises in its address.
     *  secret = The registration secret, or null for an open grid.
     *
     * Returns:
     *  A configured hub with routes registered.
     */
    static Hub start(ushort port = 4444, string secret = null)
    {
        Hub ret = new Hub();
        ret.address = "http://127.0.0.1:"~port.to!string;
        ret.secret = secret;
        ret.router = new Router();
        ret.registerRoutes();
        return ret;
    }

    /// Releases the route table and node registry. Idempotent.
    void stop()
    {
        router = null;
        nodes = null;
        sessions = null;
    }

    /// The current grid status, built from the node registry.
    GridStatus status()
    {
        GridStatus ret;
        ret.ready = nodes.length > 0;
        ret.message = nodes.length > 0 ? "Selenium Grid ready." : "No nodes registered.";
        foreach (node; nodes.byValue)
            ret.nodes ~= node;
        return ret;
    }

    /**
     * Registers or refreshes a node in the registry.
     *
     * Forward-thinking seam for the node registration endpoint. The live heartbeat
     * that calls this from a node is not yet wired.
     *
     * Params:
     *  node = The node status to record, keyed by its `id`.
     */
    void registerNode(NodeInfo node)
    {
        nodes[node.id] = node;
    }

    /**
     * Removes a node from the registry.
     *
     * Params:
     *  nodeId = The node id to remove.
     */
    void removeNode(string nodeId)
    {
        nodes.remove(nodeId);
    }

package:

    /// Registers every grid endpoint on the router.
    void registerRoutes()
    {
        router.add("GET", "/status", &handleStatus);
        router.add("DELETE", "/session/<sessionId>", &handleDeleteSession);
        router.add("DELETE", "/se/grid/distributor/node/<nodeId>", &handleRemoveNode);
        router.add("POST", "/se/grid/distributor/node/<nodeId>/drain", &handleDrainNode);
    }

    Response handleStatus(Request request)
        => Response.okValue(status().toJSON());

    Response handleDeleteSession(Request request)
    {
        // Forward-thinking: forward the delete to the owning node.
        // For the scaffold, drop the session locally if known.
        string sessionId = request.params["sessionId"];
        if (sessionId in sessions)
            sessions.remove(sessionId);

        return Response.okValue(JSONValue.emptyObject);
    }

    Response handleRemoveNode(Request request)
    {
        if (!checkSecret(request))
            return Response.error(403, "Forbidden", "unknown command", "Invalid registration secret.");

        string nodeId = request.params["nodeId"];
        if (nodeId !in nodes)
            return Response.error(404, "Not Found", "unknown command", "No node with id "~nodeId);

        nodes.remove(nodeId);
        return Response.okValue(JSONValue.emptyObject);
    }

    Response handleDrainNode(Request request)
    {
        if (!checkSecret(request))
            return Response.error(403, "Forbidden", "unknown command", "Invalid registration secret.");

        string nodeId = request.params["nodeId"];
        if (nodeId !in nodes)
            return Response.error(404, "Not Found", "unknown command", "No node with id "~nodeId);

        NodeInfo node = nodes[nodeId];
        node.availability = Availability.Draining;
        nodes[nodeId] = node;
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
