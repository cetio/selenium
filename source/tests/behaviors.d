module tests.behaviors;

import selenium.locator;
import selenium.types;
import std.json : JSONType, JSONValue;

unittest
{
    ElementLocator ret = byId("foo");
    assert(ret.strategy == LocatorStrategy.Id);
    assert(ret.value == "foo");
}

unittest
{
    ElementLocator ret = byClass("bar");
    assert(ret.strategy == LocatorStrategy.ClassName);
    assert(ret.value == "bar");
}

unittest
{
    ElementLocator ret = byCss("#baz");
    assert(ret.strategy == LocatorStrategy.CssSelector);
    assert(ret.value == "#baz");
}

unittest
{
    ElementLocator ret = byName("qux");
    assert(ret.strategy == LocatorStrategy.Name);
    assert(ret.value == "qux");
}

unittest
{
    ElementLocator ret = byLinkText("hello");
    assert(ret.strategy == LocatorStrategy.LinkText);
    assert(ret.value == "hello");
}

unittest
{
    ElementLocator ret = byPartialLinkText("partial");
    assert(ret.strategy == LocatorStrategy.PartialLinkText);
    assert(ret.value == "partial");
}

unittest
{
    ElementLocator ret = byTag("div");
    assert(ret.strategy == LocatorStrategy.TagName);
    assert(ret.value == "div");
}

unittest
{
    ElementLocator ret = byXPath("//body");
    assert(ret.strategy == LocatorStrategy.XPath);
    assert(ret.value == "//body");
}

unittest
{
    Capabilities ret = Capabilities.chrome;
    assert(ret.browserName == Browser.Chrome);
}

unittest
{
    Capabilities ret;
    JSONValue json = ret.toJSONValue();
    assert(json.type == JSONType.object);
}

unittest
{
    Capabilities ret = Capabilities.chrome;
    JSONValue json = ret.toJSONValue();
    assert("browserName" in json);
    assert(json["browserName"].str == "chrome");
}

unittest
{
    Cookie ret = Cookie("name", "value");
    assert(ret.name == "name");
    assert(ret.value == "value");
}

unittest
{
    Size ret = Size(400, 500);
    assert(ret.width == 400);
    assert(ret.height == 500);
}

unittest
{
    Position ret = Position(10, 20);
    assert(ret.x == 10);
    assert(ret.y == 20);
}

unittest
{
    WebElement ret = WebElement("elem-123");
    assert(ret.id == "elem-123");
}

unittest
{
    assert(cast(string)Browser.Chrome == "chrome");
    assert(cast(string)Browser.Firefox == "firefox");
}

unittest
{
    assert(cast(string)Platform.Linux == "Linux");
    assert(cast(string)Platform.Mac == "Mac");
    assert(cast(string)Platform.Windows == "Windows");
}

unittest
{
    assert(cast(string)LocatorStrategy.Id == "id");
    assert(cast(string)LocatorStrategy.CssSelector == "css selector");
    assert(cast(string)LocatorStrategy.TagName == "tag name");
}
