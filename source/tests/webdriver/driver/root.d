module tests.webdriver.driver.root;

import selenium.driver : Driver;
import selenium.element : By, Element;
import selenium.root : Root, RootState, RootType;
import selenium.exception : NoSuchShadowRootException;

import unit_threaded;

version(chrome)
{
    import tests.common;

    @Name("roots returns primary document first") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body><p>hello</p></body></html>"));
            Root[] roots = driver.roots();
            roots.length.shouldBeGreaterThan(0);
            roots[0].type.should == RootType.Primary;
        });
    }

    @Name("roots discovers iframe as embedded") @Serial
    unittest
    {
        testAll((driver) {
            string iframeHtml = "<p id='inner'>inside</p>";
            string html = "<html><body><iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";
            driver.go(dataUri(html));
            Root[] roots = driver.roots();
            roots.length.shouldBeGreaterThan(1);

            bool foundEmbedded;
            foreach (root; roots)
            {
                if (root.type == RootType.Embedded)
                {
                    foundEmbedded = true;
                    break;
                }
            }
            foundEmbedded.should == true;
        });
    }

    @Name("embedded root find searches inside iframe") @Serial
    unittest
    {
        testAll((driver) {
            string iframeHtml = "<p id='nested'>nested</p>";
            string html = "<html><body><iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";
            driver.go(dataUri(html));
            Root[] roots = driver.roots();

            Root embedded;
            foreach (root; roots)
            {
                if (root.type == RootType.Embedded)
                {
                    embedded = root;
                    break;
                }
            }
            embedded.shouldNotBeNull;
            embedded.find(By.css("#nested")).text.should == "nested";
        });
    }

    @Name("element shadowRoot returns shadow root") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri(
                `<html><body>`~
                `<div id="host"></div>`~
                `<script>`~
                `document.getElementById("host").attachShadow({mode:"open"});`~
                `document.getElementById("host").shadowRoot.innerHTML = "<p id='shady'>shadow</p>";`~
                `</script>`~
                `</body></html>`
            ));
            Element host = driver.find(By.css("#host"));
            Root sr = host.shadowRoot();
            sr.type.should == RootType.Shadow;
            sr.find(By.css("#shady")).text.should == "shadow";
        });
    }

    @Name("roots discovers open shadow root") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri(
                `<html><body>`~
                `<div id="host"></div>`~
                `<script>`~
                `document.getElementById("host").attachShadow({mode:"open"});`~
                `document.getElementById("host").shadowRoot.innerHTML = "<p>shadow</p>";`~
                `</script>`~
                `</body></html>`
            ));
            Root[] roots = driver.roots();
            bool foundShadow;
            foreach (root; roots)
            {
                if (root.type == RootType.Shadow)
                {
                    foundShadow = true;
                    break;
                }
            }
            foundShadow.should == true;
        });
    }

    @Name("shadowRoot throws when absent") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri("<html><body><div id='plain'>no shadow</div></body></html>"));
            Element plain = driver.find(By.css("#plain"));
            plain.shadowRoot().shouldThrow!NoSuchShadowRootException;
        });
    }

    @Name("shadow root findAll preserves order and returns empty results") @Serial
    unittest
    {
        testAll((driver) {
            driver.go(dataUri(
                `<html><body>`~
                `<div id="host"></div>`~
                `<script>`~
                `document.getElementById("host").attachShadow({mode:"open"});`~
                `document.getElementById("host").shadowRoot.innerHTML = `~
                `"<p class='item'>first</p><p class='item'>second</p>";`~
                `</script>`~
                `</body></html>`
            ));

            Root shadow = driver.find(By.css("#host")).shadowRoot();
            Element[] elements = shadow.findAll(By.css(".item"));
            elements.length.should == 2;
            elements[0].text.should == "first";
            elements[1].text.should == "second";
            shadow.findAll(By.css(".missing")).length.should == 0;
        });
    }

    @Name("embedded root findAll preserves order") @Serial
    unittest
    {
        testAll((driver) {
            string iframeHtml = "<p class='item'>first</p><p class='item'>second</p>";
            string html = "<html><body><iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";
            driver.go(dataUri(html));

            Root embedded;
            foreach (root; driver.roots())
            {
                if (root.type == RootType.Embedded)
                {
                    embedded = root;
                    break;
                }
            }

            embedded.shouldNotBeNull;
            Element[] elements = embedded.findAll(By.css(".item"));
            elements.length.should == 2;
            elements[0].text.should == "first";
            elements[1].text.should == "second";
        });
    }
}
