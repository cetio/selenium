module tests.common;

import std.uri : encodeComponent;

string dataUri(string html)
    => "data:text/html;charset=utf-8,"~encodeComponent(html);

version(integration)
{
    import std.stdio : writeln;
    import selenium.browser : Browser;
    import selenium.browser.chrome : Chrome;
    import selenium.browser.firefox : Firefox;
    import selenium.driver : Driver;
    import selenium.error : WebDriverConnectionError;

    Browser[] testBrowsers()
    {
        return [
            new Chrome(),
            new Firefox(),
        ];
    }

    // static this()
    // {
    //     foreach (browser; testBrowsers())
    //     {
    //         writeln(browser.name, ": IS INSTALLED? ", browser.isInstalled());
    //     }
    // }

    void testWithBrowsers(void delegate(Driver driver) dg)
    {
        foreach (browser; testBrowsers())
        {
            Driver driver;
            try
                driver = Driver.start(browser);
            catch (WebDriverConnectionError)
            {
                writeln("Skipping "~browser.name~" (not available).");
                continue;
            }
            scope (exit) driver.stop();
            dg(driver);
        }
    }
}