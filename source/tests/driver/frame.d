module tests.driver.frame;

import selenium.driver : Driver;
import selenium.element : By, Element;

// ========== Offline tests ==========

unittest
{
    assert(By.css("div.test").toJSON()["using"].str == "css selector");
    assert(By.css("div.test").toJSON()["value"].str == "div.test");
}

unittest
{
    assert(By.xpath("//div[@class='test']").toJSON()["using"].str == "xpath");
    assert(By.xpath("//div[@class='test']").toJSON()["value"].str == "//div[@class='test']");
}

unittest
{
    assert(By.tagName("span").toJSON()["using"].str == "tag name");
    assert(By.tagName("span").toJSON()["value"].str == "span");
}

unittest
{
    assert(By.linkText("Click me").toJSON()["using"].str == "link text");
    assert(By.linkText("Click me").toJSON()["value"].str == "Click me");
}

unittest
{
    assert(By.partialLinkText("Click").toJSON()["using"].str == "partial link text");
    assert(By.partialLinkText("Click").toJSON()["value"].str == "Click");
}

version(integration)
{
    import tests.common;

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        string inner = "<p id='inner'>inside</p>";
        string html = "<html><body>"~
            "<p id='top'>top</p>"~
            "<iframe id='frame1' srcdoc=\""~inner~"\"></iframe>"~
            "</body></html>";

        driver.go(dataUri(html));
        driver.frame.switchTo(0);
        assert(driver.find(By.css("#inner")).text == "inside");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        string iframeHtml = "<p id='nested'>nested</p>";
        string html = "<html><body><iframe id='frame1' srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

        driver.go(dataUri(html));
        Element iframe = driver.find(By.css("iframe"));
        driver.frame.switchTo(iframe);
        assert(driver.find(By.css("#nested")).text == "nested");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        string iframeHtml = "<p id='child'>child</p>";
        string html = "<html><body><p id='parent'>parent</p><iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

        driver.go(dataUri(html));
        driver.frame.switchTo(0);
        assert(driver.find(By.css("#child")).text == "child");
        driver.frame.switchToParent();
        assert(driver.find(By.css("#parent")).text == "parent");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        string iframeHtml = "<p id='deep'>deep</p>";
        string html = "<html><body><p id='surface'>surface</p>"~
            "<iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

        driver.go(dataUri(html));
        assert(driver.find(By.css("#surface")).text == "surface");
        driver.frame.switchTo(0);
        assert(driver.find(By.css("#deep")).text == "deep");
        driver.frame.switchTo();
        assert(driver.find(By.css("#surface")).text == "surface");
    }
}
