module tests.driver.frame;

import selenium.driver : Driver;
import selenium.element : By, Element;

import unit_threaded;

// ========== Offline tests ==========

@Name("By.css serializes correctly")
unittest
{
    By.css("div.test").toJSON()["using"].str.should == "css selector";
    By.css("div.test").toJSON()["value"].str.should == "div.test";
}

@Name("By.xpath serializes correctly")
unittest
{
    By.xpath("//div[@class='test']").toJSON()["using"].str.should == "xpath";
    By.xpath("//div[@class='test']").toJSON()["value"].str.should == "//div[@class='test']";
}

@Name("By.tagName serializes correctly")
unittest
{
    By.tagName("span").toJSON()["using"].str.should == "tag name";
    By.tagName("span").toJSON()["value"].str.should == "span";
}

@Name("By.linkText serializes correctly")
unittest
{
    By.linkText("Click me").toJSON()["using"].str.should == "link text";
    By.linkText("Click me").toJSON()["value"].str.should == "Click me";
}

@Name("By.partialLinkText serializes correctly")
unittest
{
    By.partialLinkText("Click").toJSON()["using"].str.should == "partial link text";
    By.partialLinkText("Click").toJSON()["value"].str.should == "Click";
}

version(integration)
{
    import tests.common;

    @Name("frame switch by index") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            string inner = "<p id='inner'>inside</p>";
            string html = "<html><body>"~
                "<p id='top'>top</p>"~
                "<iframe id='frame1' srcdoc=\""~inner~"\"></iframe>"~
                "</body></html>";

            driver.go(dataUri(html));
            driver.frame.switchTo(0);
            driver.find(By.css("#inner")).text.should == "inside";
        });
    }

    @Name("frame switch by element") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            string iframeHtml = "<p id='nested'>nested</p>";
            string html = "<html><body><iframe id='frame1' srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

            driver.go(dataUri(html));
            Element iframe = driver.find(By.css("iframe"));
            driver.frame.switchTo(iframe);
            driver.find(By.css("#nested")).text.should == "nested";
        });
    }

    @Name("frame switch to parent") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            string iframeHtml = "<p id='child'>child</p>";
            string html = "<html><body><p id='parent'>parent</p>"~
                "<iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

            driver.go(dataUri(html));
            driver.frame.switchTo(0);
            driver.find(By.css("#child")).text.should == "child";
            driver.frame.switchToParent();
            driver.find(By.css("#parent")).text.should == "parent";
        });
    }

    @Name("frame switch to top") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            string iframeHtml = "<p id='deep'>deep</p>";
            string html = "<html><body><p id='surface'>surface</p>"~
                "<iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

            driver.go(dataUri(html));
            driver.find(By.css("#surface")).text.should == "surface";
            driver.frame.switchTo(0);
            driver.find(By.css("#deep")).text.should == "deep";
            driver.frame.switchTo();
            driver.find(By.css("#surface")).text.should == "surface";
        });
    }
}
