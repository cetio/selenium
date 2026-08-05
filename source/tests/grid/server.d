module tests.grid.server;

import selenium.grid.server.http;
import selenium.grid.server.hub;
import selenium.grid.server.model;
import selenium.grid.server.node;

import selenium.browser : Browser;
import selenium.browser.chrome : Chrome;

import unit_threaded;

import std.json : JSONValue, JSONType, parseJSON;

@Name("Stereotype roundtrips through toJSON/fromJSON")
unittest
{
    Stereotype stereotype;
    stereotype.capabilities = parseJSON(`{"browserName":"chrome","platformName":"Linux"}`);

    Stereotype roundTrip = Stereotype.fromJSON(stereotype.toJSON());
    roundTrip.capabilities["browserName"].str.should == "chrome";
    roundTrip.capabilities["platformName"].str.should == "Linux";
}

@Name("Slot roundtrips occupied and free states")
unittest
{
    Slot occupied;
    occupied.id = "0";
    occupied.stereotype.capabilities = parseJSON(`{"browserName":"chrome"}`);
    occupied.sessionId = "sess-1";

    Slot occupiedRoundTrip = Slot.fromJSON(occupied.toJSON());
    occupiedRoundTrip.id.should == "0";
    occupiedRoundTrip.occupied.should == true;
    occupiedRoundTrip.sessionId.should == "sess-1";

    Slot free;
    free.id = "1";
    free.stereotype.capabilities = parseJSON(`{"browserName":"firefox"}`);

    Slot freeRoundTrip = Slot.fromJSON(free.toJSON());
    freeRoundTrip.occupied.should == false;
    freeRoundTrip.sessionId.length.should == 0;
}

@Name("NodeInfo roundtrips through the value envelope")
unittest
{
    NodeInfo node;
    node.id = "node-1";
    node.uri = "http://127.0.0.1:5555";
    node.maxSessions = 2;
    node.availability = Availability.Up;

    Slot slot;
    slot.id = "0";
    slot.stereotype.capabilities = parseJSON(`{"browserName":"chrome"}`);
    node.slots ~= slot;

    JSONValue envelope = JSONValue.emptyObject;
    envelope["value"] = node.toJSON();

    NodeInfo roundTrip = NodeInfo.fromJSON(envelope);
    roundTrip.id.should == "node-1";
    roundTrip.uri.should == "http://127.0.0.1:5555";
    roundTrip.maxSessions.should == 2;
    roundTrip.availability.should == Availability.Up;
    roundTrip.slots.length.should == 1;
    roundTrip.slots[0].id.should == "0";
}

@Name("GridStatus roundtrips ready and nodes")
unittest
{
    NodeInfo node;
    node.id = "node-1";
    node.uri = "http://127.0.0.1:5555";
    node.maxSessions = 1;
    node.availability = Availability.Up;

    GridStatus status;
    status.ready = true;
    status.message = "Selenium Grid ready.";
    status.nodes ~= node;

    GridStatus roundTrip = GridStatus.fromJSON(status.toJSON());
    roundTrip.ready.should == true;
    roundTrip.message.should == "Selenium Grid ready.";
    roundTrip.nodes.length.should == 1;
    roundTrip.nodes[0].id.should == "node-1";
}

@Name("SessionInfo roundtrips id and nodeId")
unittest
{
    SessionInfo session;
    session.id = "sess-1";
    session.nodeId = "node-1";
    session.capabilities = parseJSON(`{"browserName":"chrome"}`);

    SessionInfo roundTrip = SessionInfo.fromJSON(session.toJSON());
    roundTrip.id.should == "sess-1";
    roundTrip.nodeId.should == "node-1";
    roundTrip.capabilities["browserName"].str.should == "chrome";
}

@Name("Router extracts path parameters and dispatches")
unittest
{
    Router router = new Router();
    router.add("GET", "/se/grid/node/owner/<sessionId>", delegate(Request request) {
        return Response.okValue(JSONValue(request.params["sessionId"]));
    });

    Request request = Request("GET", "/se/grid/node/owner/sess-42");
    Response response = router.dispatch(request);
    response.status.should == 200;
    JSONValue json = parseJSON(cast(string)response.content);
    json["value"].str.should == "sess-42";
}

@Name("Router returns 404 for unmatched paths")
unittest
{
    Router router = new Router();
    router.add("GET", "/status", delegate(Request request) {
        return Response.okValue(JSONValue.emptyObject);
    });

    Response response = router.dispatch(Request("GET", "/unknown"));
    response.status.should == 404;
}

@Name("Router does not match across methods")
unittest
{
    Router router = new Router();
    router.add("GET", "/status", delegate(Request request) {
        return Response.okValue(JSONValue.emptyObject);
    });

    Response response = router.dispatch(Request("DELETE", "/status"));
    response.status.should == 404;
}

@Name("Hub GET /status reports not ready with no nodes")
unittest
{
    Hub hub = Hub.start();
    scope (exit) hub.stop();

    Response response = hub.router.dispatch(Request("GET", "/status"));
    response.status.should == 200;
    JSONValue json = parseJSON(cast(string)response.content);
    (json["value"]["ready"].type == JSONType.false_).should == true;
    json["value"]["nodes"].array.length.should == 0;
}

@Name("Hub GET /status reports ready after registering a node")
unittest
{
    Hub hub = Hub.start();
    scope (exit) hub.stop();

    NodeInfo node;
    node.id = "node-1";
    node.uri = "http://127.0.0.1:5555";
    node.maxSessions = 1;
    node.availability = Availability.Up;
    hub.registerNode(node);

    Response response = hub.router.dispatch(Request("GET", "/status"));
    JSONValue json = parseJSON(cast(string)response.content);
    (json["value"]["ready"].type == JSONType.true_).should == true;
    json["value"]["nodes"].array.length.should == 1;
    json["value"]["nodes"][0]["id"].str.should == "node-1";
}

@Name("Hub distributor remove node honors the registration secret")
unittest
{
    Hub hub = Hub.start(4444, "s3cr3t");
    scope (exit) hub.stop();

    NodeInfo node;
    node.id = "node-1";
    hub.registerNode(node);

    Request unauthed = Request("DELETE", "/se/grid/distributor/node/node-1");
    hub.router.dispatch(unauthed).status.should == 403;
    hub.nodes.length.should == 1;

    Request authed = Request("DELETE", "/se/grid/distributor/node/node-1");
    authed.headers["x-registration-secret"] = "s3cr3t";
    hub.router.dispatch(authed).status.should == 200;
    hub.nodes.length.should == 0;
}

@Name("Hub distributor drain marks the node draining")
unittest
{
    Hub hub = Hub.start(4444, "s3cr3t");
    scope (exit) hub.stop();

    NodeInfo node;
    node.id = "node-1";
    node.availability = Availability.Up;
    hub.registerNode(node);

    Request request = Request("POST", "/se/grid/distributor/node/node-1/drain");
    request.headers["x-registration-secret"] = "s3cr3t";
    hub.router.dispatch(request).status.should == 200;
    hub.nodes["node-1"].availability.should == Availability.Draining;
}

@Name("Hub delete session drops a known session")
unittest
{
    Hub hub = Hub.start();
    scope (exit) hub.stop();

    SessionInfo session;
    session.id = "sess-1";
    session.nodeId = "node-1";
    hub.sessions[session.id] = session;

    hub.router.dispatch(Request("DELETE", "/session/sess-1")).status.should == 200;
    hub.sessions.length.should == 0;
}

@Name("Node GET /status reports slot stereotypes from browsers")
unittest
{
    Chrome chrome = new Chrome();
    Node node = Node.start([chrome]);
    scope (exit) node.stop();

    Response response = node.router.dispatch(Request("GET", "/status"));
    response.status.should == 200;
    JSONValue json = parseJSON(cast(string)response.content);
    json["value"]["id"].str.should == "http://127.0.0.1:5555";
    json["value"]["maxSessions"].integer.should == 1;
    json["value"]["slots"].array.length.should == 1;
    json["value"]["slots"][0]["stereotype"]["browserName"].str.should == "chrome";
}

@Name("Node owner endpoint reports session ownership")
unittest
{
    Chrome chrome = new Chrome();
    Node node = Node.start([chrome], null, 5555, "s3cr3t");
    scope (exit) node.stop();

    node.slots[0].sessionId = "sess-1";

    Request ownerRequest = Request("GET", "/se/grid/node/owner/sess-1");
    ownerRequest.headers["x-registration-secret"] = "s3cr3t";
    JSONValue json = parseJSON(cast(string)node.router.dispatch(ownerRequest).content);
    (json["value"].type == JSONType.true_).should == true;

    Request unknownRequest = Request("GET", "/se/grid/node/owner/sess-99");
    unknownRequest.headers["x-registration-secret"] = "s3cr3t";
    JSONValue unknownJSON = parseJSON(cast(string)node.router.dispatch(unknownRequest).content);
    (unknownJSON["value"].type == JSONType.false_).should == true;
}

@Name("Node delete session frees an occupied slot")
unittest
{
    Chrome chrome = new Chrome();
    Node node = Node.start([chrome], null, 5555, "s3cr3t");
    scope (exit) node.stop();

    node.slots[0].sessionId = "sess-1";
    node.slots[0].occupied.should == true;

    Request request = Request("DELETE", "/se/grid/node/session/sess-1");
    request.headers["x-registration-secret"] = "s3cr3t";
    node.router.dispatch(request).status.should == 200;
    node.slots[0].occupied.should == false;
}

@Name("Node endpoints reject a missing registration secret")
unittest
{
    Chrome chrome = new Chrome();
    Node node = Node.start([chrome], null, 5555, "s3cr3t");
    scope (exit) node.stop();

    node.router.dispatch(Request("POST", "/se/grid/node/drain")).status.should == 403;
}
