module tests.driver.element;

import selenium.driver : Driver;
import selenium.element : By, Element;
import selenium.error : StaleElementReferenceError;

import unit_threaded;

version(integration)
{
    import tests.common;

    @Name("click updates button text") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><button id='btn' onclick='this.textContent=\"clicked\"'>click</button></body></html>"
            ));
            driver.find(By.css("#btn")).click();
            driver.find(By.css("#btn")).text.should == "clicked";
        });
    }

    @Name("sendKeys sets input value") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='field' value='initial'></body></html>"
            ));
            driver.find(By.css("#field")).clear();
            driver.find(By.css("#field")).sendKeys("abc");
            driver.find(By.css("#field")).property("value").should == "abc";
        });
    }

    @Name("clear empties input field") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='field' value='prefilled'></body></html>"
            ));
            driver.find(By.css("#field")).clear();
            driver.find(By.css("#field")).property("value").should == "";
        });
    }

    @Name("nested element find") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><div id='outer'><span id='inner'>nested</span></div></body></html>"
            ));
            Element outer = driver.find(By.css("#outer"));
            outer.find(By.css("#inner")).text.should == "nested";
        });
    }

    @Name("cssValue returns style value") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><p id='t' style='color:red;'>styled</p></body></html>"
            ));
            driver.find(By.css("#t")).cssValue("color").length.shouldBeGreaterThan(0);
        });
    }

    @Name("stale element access throws") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='stale' value='old'></body></html>"
            ));
            Element elem = driver.find(By.css("#stale"));
            driver.refresh();

            elem.attribute("value").shouldThrow!StaleElementReferenceError;
        });
    }

    @Name("selected reflects checkbox state") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='checky' type='checkbox' checked>"
                ~"<input id='unchecky' type='checkbox'></body></html>"
            ));
            driver.find(By.css("#checky")).selected.should == true;
            driver.find(By.css("#unchecky")).selected.should == false;
        });
    }

    @Name("enabled reflects element state") @Serial
    unittest
    {
        testWithBrowsers((driver) {
            driver.go(dataUri(
                "<html><body><input id='dis' disabled><input id='en'></body></html>"
            ));
            driver.find(By.css("#dis")).enabled.should == false;
            driver.find(By.css("#en")).enabled.should == true;
        });
    }
}
