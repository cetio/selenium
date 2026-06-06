module tests.driver.element;

import selenium.driver : Driver;
import selenium.element : By, Element;

version(integration)
{
    import tests.common;

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><button id='btn' onclick='this.textContent=\"clicked\"'>click</button></body></html>"
            ));
            driver.find(By.css("#btn")).click();
            assert(driver.find(By.css("#btn")).text == "clicked", "click failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='field' value='initial'></body></html>"
            ));
            driver.find(By.css("#field")).clear();
            driver.find(By.css("#field")).sendKeys("abc");
            assert(driver.find(By.css("#field")).property("value") == "abc",
                "sendKeys failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='field' value='prefilled'></body></html>"
            ));
            driver.find(By.css("#field")).clear();
            assert(driver.find(By.css("#field")).property("value") == "", "clear failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><div id='outer'><span id='inner'>nested</span></div></body></html>"
            ));
            Element outer = driver.find(By.css("#outer"));
            assert(outer.find(By.css("#inner")).text == "nested", "nested find failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><p id='t' style='color:red;'>styled</p></body></html>"
            ));
            assert(driver.find(By.css("#t")).cssValue("color").length > 0, "cssValue failed for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='stale' value='old'></body></html>"
            ));
            Element elem = driver.find(By.css("#stale"));
            driver.refresh();

            bool threw = false;
            try
                elem.attribute("value");
            catch (Exception)
                threw = true;
            assert(threw, "stale element did not throw for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='checky' type='checkbox' checked>"
                ~"<input id='unchecky' type='checkbox'></body></html>"
            ));
            assert(driver.find(By.css("#checky")).selected == true, "checked expected for "~driver.browser.name);
            assert(driver.find(By.css("#unchecky")).selected == false, "unchecked expected for "~driver.browser.name);
        });
    }

    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='dis' disabled><input id='en'></body></html>"
            ));
            assert(driver.find(By.css("#dis")).enabled == false, "disabled expected for "~driver.browser.name);
            assert(driver.find(By.css("#en")).enabled == true, "enabled expected for "~driver.browser.name);
        });
    }
}
