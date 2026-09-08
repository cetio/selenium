module tests.webdriver.driver.frame;

import selenium.element : By;

import unit_threaded;

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
