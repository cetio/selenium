module tests.behaviors;

import selenium.api;
import std.json : JSONValue, JSONType;

unittest
{
    ElementLocator ret = idLocator("foo");
    assert(ret.using == LocatorStrategy.Id);
    assert(ret.value == "foo");
}

unittest
{
    ElementLocator ret = classLocator("bar");
    assert(ret.using == LocatorStrategy.ClassName);
    assert(ret.value == "bar");
}

unittest
{
    ElementLocator ret = cssLocator("#baz");
    assert(ret.using == LocatorStrategy.CssSelector);
    assert(ret.value == "#baz");
}

unittest
{
    ElementLocator ret = nameLocator("qux");
    assert(ret.using == LocatorStrategy.Name);
    assert(ret.value == "qux");
}

unittest
{
    ElementLocator ret = linkTextLocator("hello");
    assert(ret.using == LocatorStrategy.LinkText);
    assert(ret.value == "hello");
}

unittest
{
    ElementLocator ret = partialLinkTextLocator("partial");
    assert(ret.using == LocatorStrategy.PartialLinkText);
    assert(ret.value == "partial");
}

unittest
{
    ElementLocator ret = tagLocator("div");
    assert(ret.using == LocatorStrategy.TagName);
    assert(ret.value == "div");
}

unittest
{
    ElementLocator ret = xpathLocator("//body");
    assert(ret.using == LocatorStrategy.XPath);
    assert(ret.value == "//body");
}

unittest
{
    Capabilities ret = Capabilities.chrome;
    assert(ret.browserName == Browser.chrome);
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
    assert(ret.ELEMENT == "elem-123");
}

unittest
{
    assert(cast(string)Browser.chrome == "chrome");
    assert(cast(string)Browser.firefox == "firefox");
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
