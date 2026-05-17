module selenium.locator;

import selenium.types : LocatorStrategy;

public:

struct ElementLocator
{
    LocatorStrategy strategy;
    string value;
}

ElementLocator byClass(string value)
{
    return ElementLocator(LocatorStrategy.ClassName, value);
}

ElementLocator byCss(string value)
{
    return ElementLocator(LocatorStrategy.CssSelector, value);
}

ElementLocator byId(string value)
{
    return ElementLocator(LocatorStrategy.Id, value);
}

ElementLocator byName(string value)
{
    return ElementLocator(LocatorStrategy.Name, value);
}

ElementLocator byLinkText(string value)
{
    return ElementLocator(LocatorStrategy.LinkText, value);
}

ElementLocator byPartialLinkText(string value)
{
    return ElementLocator(LocatorStrategy.PartialLinkText, value);
}

ElementLocator byTag(string value)
{
    return ElementLocator(LocatorStrategy.TagName, value);
}

ElementLocator byXPath(string value)
{
    return ElementLocator(LocatorStrategy.XPath, value);
}
