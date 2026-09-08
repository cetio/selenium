module tests.webdriver.driver.element;

import selenium.driver : Driver;
import selenium.element : By, Element;
import selenium.exception : StaleElementReferenceException;

import unit_threaded;

version(chrome)
{
    import tests.common;

    @Name("click updates button text") @Serial
    unittest
    {
        testAll((driver) {
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
        testAll((driver) {
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
        testAll((driver) {
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
        testAll((driver) {
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
        testAll((driver) {
            driver.go(dataUri(
                "<html><body><p id='t' style='color:red;'>styled</p></body></html>"
            ));
            driver.find(By.css("#t")).cssValue("color").length.shouldBeGreaterThan(0);
        });
    }

    @Name("stale element access throws") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri(
                "<html><body><input id='stale' value='old'></body></html>"
            ));
            Element elem = driver.find(By.css("#stale"));
            driver.refresh();

            elem.attribute("value").shouldThrow!StaleElementReferenceException;
        });
    }

    @Name("selected reflects checkbox state") @Serial
    unittest
    {
        testAll((driver) {
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
        testAll((driver) {
            driver.go(dataUri(
                "<html><body><input id='dis' disabled><input id='en'></body></html>"
            ));
            driver.find(By.css("#dis")).enabled.should == false;
            driver.find(By.css("#en")).enabled.should == true;
        });
    }

    @Name("driver findAll preserves order and returns empty results") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri(
                "<html><body><p class='item'>first</p><p class='item'>second</p></body></html>"
            ));

            Element[] elements = driver.findAll(By.css(".item"));
            elements.length.should == 2;
            elements[0].text.should == "first";
            elements[1].text.should == "second";
            driver.findAll(By.css(".missing")).length.should == 0;
        });
    }

    @Name("element findAll stays within descendant scope") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri(
                "<html><body>"~
                "<section id='first'><span class='item'>inside</span></section>"~
                "<section><span class='item'>outside</span></section>"~
                "</body></html>"
            ));

            Element section = driver.find(By.css("#first"));
            Element[] elements = section.findAll(By.css(".item"));
            elements.length.should == 1;
            elements[0].text.should == "inside";
            section.findAll(By.css(".missing")).length.should == 0;
        });
    }
}
