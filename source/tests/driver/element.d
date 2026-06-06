module tests.driver.element;

import selenium.driver : Driver;
import selenium.element : By, Element;

version(integration)
{
    import tests.common;

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><button id='btn' onclick='this.textContent=\"clicked\"'>click</button></body></html>"
        ));
        driver.find(By.css("#btn")).click();
        assert(driver.find(By.css("#btn")).text == "clicked");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='field' value='initial'></body></html>"
        ));
        driver.find(By.css("#field")).sendKeys("abc");
        assert(driver.find(By.css("#field")).attribute("value") == "abc");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='field' value='prefilled'></body></html>"
        ));
        driver.find(By.css("#field")).clear();
        assert(driver.find(By.css("#field")).attribute("value") == "");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><div id='outer'><span id='inner'>nested</span></div></body></html>"
        ));
        Element outer = driver.find(By.css("#outer"));
        assert(outer.find(By.css("#inner")).text == "nested");
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><p id='t' style='color:red;'>styled</p></body></html>"
        ));
        assert(driver.find(By.css("#t")).cssValue("color").length > 0);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

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
        assert(threw);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='checky' type='checkbox' checked><input id='unchecky' type='checkbox'></body></html>"
        ));
        assert(driver.find(By.css("#checky")).selected == true);
        assert(driver.find(By.css("#unchecky")).selected == false);
    }

    unittest
    {
        Driver driver = Driver.start();
        scope (exit) driver.stop();

        driver.go(dataUri(
            "<html><body><input id='dis' disabled><input id='en'></body></html>"
        ));
        assert(driver.find(By.css("#dis")).enabled == false);
        assert(driver.find(By.css("#en")).enabled == true);
    }
}
