module tests.unit.bridge;

import selenium.bridge : Bridge;

import std.json : JSONValue, parseJSON;

unittest
{
    JSONValue json = parseJSON(`{"value":{"element-6066-11e4-a52e-4f735466cecf":"abc123"}}`);
    assert(Bridge.parseElementId(json) == "abc123");
}

unittest
{
    JSONValue json = parseJSON(`{"value":{"ELEMENT":"legacy456"}}`);
    assert(Bridge.parseElementId(json) == "legacy456");
}

unittest
{
    JSONValue json = parseJSON(`{"value":{"foo":"bar"}}`);
    assert(Bridge.parseElementId(json) is null);
}

unittest
{
    JSONValue json = parseJSON(`{"value":"not-an-object"}`);
    assert(Bridge.parseElementId(json) is null);
}

unittest
{
    JSONValue json = parseJSON(`{"value":"oops"}`);
    assert(Bridge.parseElementIds(json).length == 0);
}

unittest
{
    JSONValue json = parseJSON(`{"value":[
        {"element-6066-11e4-a52e-4f735466cecf":"id1"},
        {"element-6066-11e4-a52e-4f735466cecf":"id2"},
        {"element-6066-11e4-a52e-4f735466cecf":"id3"}
    ]}`);
    assert(Bridge.parseElementIds(json) == ["id1", "id2", "id3"]);
}
