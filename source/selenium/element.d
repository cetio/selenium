module selenium.element;

import selenium.driver : Driver;
import selenium.locator : ElementLocator;
import selenium.types : LocatorStrategy, Position, Size, WebElement;

public:

class Element
{
private:
    Driver _driver;
    WebElement _webElement;

public:
    this(Driver driver, WebElement webElement)
    {
        _driver = driver;
        _webElement = webElement;
    }

    string id() const
        => _webElement.id;

    // --- Search context (scoped to this element) ---

    Element findOne(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return _driver.queryElementFrom(_webElement.id, LocatorOf!strategy, value);
    }

    Element findOne(ElementLocator locator)
    {
        return _driver.queryElementFrom(
            _webElement.id,
            locator.strategy,
            locator.value
        );
    }

    Element[] findMany(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return _driver.queryElementsFrom(_webElement.id, LocatorOf!strategy, value);
    }

    Element[] findMany(ElementLocator locator)
    {
        return _driver.queryElementsFrom(
            _webElement.id,
            locator.strategy,
            locator.value
        );
    }

    // --- Properties ---

    string text()
    {
        return _driver.client.get!string(elementPath("/text"));
    }

    string tagName()
    {
        return _driver.client.get!string(elementPath("/name"));
    }

    void click()
    {
        _driver.client.post(elementPath("/click"));
    }

    void submit()
    {
        _driver.client.post(elementPath("/submit"));
    }

    void sendKeys(string[] keys)
    {
        _driver.client.post(elementPath("/value"), ["value": keys]);
    }

    void sendKeys(string keys)
    {
        sendKeys([keys]);
    }

    void clear()
    {
        _driver.client.post(elementPath("/clear"));
    }

    bool selected()
    {
        return _driver.client.get!bool(elementPath("/selected"));
    }

    bool enabled()
    {
        return _driver.client.get!bool(elementPath("/enabled"));
    }

    bool displayed()
    {
        return _driver.client.get!bool(elementPath("/displayed"));
    }

    string attribute(string name)
    {
        return _driver.client.get!string(elementPath("/attribute/" ~ name));
    }

    string cssValue(string property)
    {
        return _driver.client.get!string(elementPath("/css/" ~ property));
    }

    Position position()
    {
        return _driver.client.get!Position(elementPath("/location"));
    }

    Position positionInView()
    {
        return _driver.client.get!Position(elementPath("/location_in_view"));
    }

    Size size()
    {
        return _driver.client.get!Size(elementPath("/size"));
    }

    string screenshot()
    {
        return _driver.client.get!string(elementPath("/screenshot"));
    }

private:
    string elementPath(string suffix)
    {
        return "/element/" ~ _webElement.id ~ suffix;
    }
}
