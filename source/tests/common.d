module tests.common;

import selenium.browser.chrome : Chrome;
import selenium.driver : Driver;

import std.uri : encodeComponent;

Chrome testChrome()
{
    Chrome ret = new Chrome();
    ret.includeSwitches = ["--headless", "--no-sandbox", "--disable-dev-shm-usage"];
    return ret;
}

string dataUri(string html)
    => "data:text/html;charset=utf-8," ~ encodeComponent(html);

Driver startTestDriver()
{
    return Driver.start();
}
