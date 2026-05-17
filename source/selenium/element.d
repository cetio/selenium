module selenium.element;

import selenium.driver : Driver;
import selenium.locator : ElementLocator;
import selenium.types : LocatorOf, LocatorStrategy, Position, Size, WebElement;

class Element
{
private:
    Driver driver;
    WebElement webElement;

public:
    this(Driver driver, WebElement webElement)
    {
        this.driver = driver;
        this.webElement = webElement;
    }

    string id() const
        => webElement.id;

    // --- Search context (scoped to this element) ---

    Element findOne(string strategy)(string value)
        if (__traits(compiles, LocatorOf!strategy))
        => driver.queryElementFrom(webElement.id, LocatorOf!strategy, value);

    Element findOne(ElementLocator locator)
    {
        return driver.queryElementFrom(
            webElement.id,
            locator.strategy,
            locator.value
        );
    }

    Element[] findMany(string strategy)(string value)
        if (__traits(compiles, LocatorOf!strategy))
        => driver.queryElementsFrom(webElement.id, LocatorOf!strategy, value);

    Element[] findMany(ElementLocator locator)
    {
        return driver.queryElementsFrom(
            webElement.id,
            locator.strategy,
            locator.value
        );
    }

    // --- Properties ---

    string text()
        => driver.client.get!string(elementPath("/text"));

    string tagName()
        => driver.client.get!string(elementPath("/name"));

    void click()
    {
        driver.client.post(elementPath("/click"));
    }

    void submit()
    {
        driver.client.post(elementPath("/submit"));
    }

    void sendKeys(string[] keys)
    {
        driver.client.post(elementPath("/value"), ["value": keys]);
    }

    void sendKeys(string keys)
    {
        sendKeys([keys]);
    }

    void clear()
    {
        driver.client.post(elementPath("/clear"));
    }

    bool selected()
        => driver.client.get!bool(elementPath("/selected"));

    bool enabled()
        => driver.client.get!bool(elementPath("/enabled"));

    bool displayed()
        => driver.client.get!bool(elementPath("/displayed"));

    string attribute(string name)
    {
        return driver.client.get!string(elementPath("/attribute/"~name));
    }

    string cssValue(string property)
    {
        return driver.client.get!string(elementPath("/css/"~property));
    }

    Position position()
        => driver.client.get!Position(elementPath("/location"));

    Position positionInView()
        => driver.client.get!Position(elementPath("/location_in_view"));

    Size size()
        => driver.client.get!Size(elementPath("/size"));

    string screenshot()
    {
        return driver.client.get!string(elementPath("/screenshot"));
    }

private:
    string elementPath(string suffix)
    {
        return "/element/"~webElement.id~suffix;
    }
}
