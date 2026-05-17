module selenium.page;

import core.thread : Thread;
import core.time : Duration, seconds;
import std.conv : to;

import selenium.driver : Driver;
import selenium.element : Element;
import selenium.errors : WebDriverTimeoutError;
import selenium.locator : ElementLocator;
import selenium.types : LocatorStrategy;

public:

abstract class Page
{
private:
    Driver _driver;

public:
    this(Driver driver)
    {
        _driver = driver;
    }

    Driver driver()
        => _driver;

    abstract bool isPresent();

    void waitFor(Duration timeout = 10.seconds)
    {
        import core.time : MonoTime, msecs;

        MonoTime deadline = MonoTime.currTime + timeout;
        while (MonoTime.currTime < deadline)
        {
            if (isPresent())
                return;

            Thread.sleep(100.msecs);
        }

        throw new WebDriverTimeoutError(
            "Page did not become present within " ~ timeout.to!string
        );
    }

    Element findOne(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return _driver.findOne!strategy(value);
    }

    Element[] findMany(string strategy)(string value)
        if (is(typeof(LocatorOf!strategy) == LocatorStrategy))
    {
        return _driver.findMany!strategy(value);
    }
}
