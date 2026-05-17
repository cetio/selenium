module selenium.locator;

import selenium.types : LocatorStrategy;

import conductor.serialize.json : Name;

struct ElementLocator
{
    @Name("using")
    LocatorStrategy strategy;
    string value;
}

ElementLocator byClass(string value)
    => ElementLocator(LocatorStrategy.ClassName, value);

ElementLocator byCss(string value)
    => ElementLocator(LocatorStrategy.CssSelector, value);

ElementLocator byId(string value)
    => ElementLocator(LocatorStrategy.Id, value);

ElementLocator byName(string value)
    => ElementLocator(LocatorStrategy.Name, value);

ElementLocator byLinkText(string value)
    => ElementLocator(LocatorStrategy.LinkText, value);

ElementLocator byPartialLinkText(string value)
    => ElementLocator(LocatorStrategy.PartialLinkText, value);

ElementLocator byTag(string value)
    => ElementLocator(LocatorStrategy.TagName, value);

ElementLocator byXPath(string value)
    => ElementLocator(LocatorStrategy.XPath, value);

