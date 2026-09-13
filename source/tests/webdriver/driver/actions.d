/// Offline tests for the W3C Actions framework serialization.
module tests.webdriver.driver.actions;

import selenium.actions : Action, InputType, Source;
import selenium.actions.key : Key;
import selenium.actions.pointer : Button, Origin, PointerType;

import unit_threaded;

import std.json : JSONValue, JSONType;

@Name("Key code points occupy the Private Use Area")
unittest
{
    (cast(dchar)Key.Null).should == '\uE000';
    (cast(dchar)Key.Enter).should == '\uE007';
    (cast(dchar)Key.Shift).should == '\uE008';
    (cast(dchar)Key.F12).should == '\uE03C';
    (cast(dchar)Key.Meta).should == (cast(dchar)Key.Command);
}

@Name("PointerType values match the W3C strings")
unittest
{
    (cast(string)PointerType.Mouse).should == "mouse";
    (cast(string)PointerType.Pen).should == "pen";
    (cast(string)PointerType.Touch).should == "touch";
}

@Name("Origin values match the W3C strings")
unittest
{
    (cast(string)Origin.Viewport).should == "viewport";
    (cast(string)Origin.Pointer).should == "pointer";
}

@Name("Button values follow the W3C numbering")
unittest
{
    (cast(int)Button.Primary).should == 0;
    (cast(int)Button.Auxiliary).should == 1;
    (cast(int)Button.Secondary).should == 2;
}

@Name("pause action serializes type and duration")
unittest
{
    JSONValue json = Action.pause(250).toJSON();
    json["type"].str.should == "pause";
    json["duration"].integer.should == 250;
    (("value" in json) is null).should == true;
}

@Name("keyDown action serializes the code point as a string")
unittest
{
    JSONValue json = Action.keyDown('a').toJSON();
    json["type"].str.should == "keyDown";
    json["value"].str.should == "a";
}

@Name("keyUp action serializes a special key as its code point")
unittest
{
    JSONValue json = Action.keyUp(Key.Enter).toJSON();
    json["type"].str.should == "keyUp";
    json["value"].str.should == "\uE007";
}

@Name("pointerDown action serializes type and button only")
unittest
{
    JSONValue json = Action.pointerDown(Button.Secondary).toJSON();
    json["type"].str.should == "pointerDown";
    json["button"].integer.should == 2;
    (("duration" in json) is null).should == true;
}

@Name("pointerUp action serializes type and button only")
unittest
{
    JSONValue json = Action.pointerUp(Button.Auxiliary).toJSON();
    json["type"].str.should == "pointerUp";
    json["button"].integer.should == 1;
}

@Name("pointerCancel action serializes type and button")
unittest
{
    JSONValue json = Action.pointerCancel(Button.Primary).toJSON();
    json["type"].str.should == "pointerCancel";
    json["button"].integer.should == 0;
}

@Name("pointerMove action serializes duration origin x and y")
unittest
{
    JSONValue origin = JSONValue(cast(string)Origin.Viewport);
    JSONValue json = Action.pointerMove(10, 20, 300, origin).toJSON();
    json["type"].str.should == "pointerMove";
    json["duration"].integer.should == 300;
    json["origin"].str.should == "viewport";
    json["x"].integer.should == 10;
    json["y"].integer.should == 20;
    (("button" in json) is null).should == true;
}

@Name("scroll action serializes all wheel fields")
unittest
{
    JSONValue json = Action.scroll(1, 2, 3, 4, 500).toJSON();
    json["type"].str.should == "scroll";
    json["duration"].integer.should == 500;
    json["x"].integer.should == 1;
    json["y"].integer.should == 2;
    json["deltaX"].integer.should == 3;
    json["deltaY"].integer.should == 4;
}

@Name("key source omits the parameters object")
unittest
{
    Source src;
    src.type = InputType.Key;
    src.id = "keyboard";
    src.actions = [Action.keyDown('a'), Action.keyUp('a')];

    JSONValue json = src.toJSON();
    json["type"].str.should == "key";
    json["id"].str.should == "keyboard";
    (("parameters" in json) is null).should == true;
    json["actions"].array.length.should == 2;
    json["actions"].array[0]["type"].str.should == "keyDown";
    json["actions"].array[1]["type"].str.should == "keyUp";
}

@Name("pointer source includes the pointerType parameter")
unittest
{
    Source src;
    src.type = InputType.Pointer;
    src.id = "mouse";
    src.pointerType = PointerType.Mouse;
    src.actions = [Action.pointerDown(Button.Primary)];

    JSONValue json = src.toJSON();
    json["type"].str.should == "pointer";
    json["id"].str.should == "mouse";
    json["parameters"]["pointerType"].str.should == "mouse";
    json["actions"].array.length.should == 1;
    json["actions"].array[0]["button"].integer.should == 0;
}

@Name("wheel source omits the parameters object")
unittest
{
    Source src;
    src.type = InputType.Wheel;
    src.id = "wheel";
    src.actions = [Action.scroll(0, 0, 0, 10, 0)];

    JSONValue json = src.toJSON();
    json["type"].str.should == "wheel";
    json["id"].str.should == "wheel";
    (("parameters" in json) is null).should == true;
    json["actions"].array[0]["deltaY"].integer.should == 10;
}

@Name("none source serializes a pause action")
unittest
{
    Source src;
    src.type = InputType.None;
    src.id = "none";
    src.actions = [Action.pause(100)];

    JSONValue json = src.toJSON();
    json["type"].str.should == "none";
    json["id"].str.should == "none";
    json["actions"].array[0]["duration"].integer.should == 100;
}
