module tests.common;

import std.uri : encodeComponent;

string dataUri(string html)
    => "data:text/html;charset=utf-8,"~encodeComponent(html);

/// Mixin template for browser integration tests.
mixin template BrowserIntegration()
{
    @Name("title returns page title") @Serial
    unittest
    {
        driver.go(dataUri("<html><title>WindowTest</title><body></body></html>"));
        driver.title.should == "WindowTest";
    }

    @Name("handle returns window handle") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        driver.window.handle.length.shouldBeGreaterThan(0);
    }

    @Name("resize changes window size") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        Size original = driver.window.size;
        driver.window.resize(Size(original.width - 50, original.height - 50));
        Size changed = driver.window.size;
        changed.width.should == original.width - 50;
        changed.height.should == original.height - 50;
    }

    @Name("maximize enlarges window") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        driver.window.resize(Size(400, 400));
        driver.window.maximize();
        Size maximized = driver.window.size;
        maximized.width.shouldBeGreaterThan(399);
        maximized.height.shouldBeGreaterThan(399);
    }

    @Name("minimize hides document") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        driver.window.minimize();
        driver.execute!bool("return document.hidden;").should == true;
    }

    @Name("handles returns window list") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        driver.window.handles.length.shouldBeGreaterThan(0);
    }

    @Name("window can open switch close and restore original handle") @Serial
    unittest
    {
        string original = driver.window.handle;
        string opened = driver.window.open();

        (opened != original).should == true;
        driver.window.handles.length.should == 2;
        driver.window.switchTo(opened);
        driver.go(dataUri("<html><title>OpenedWindow</title><body></body></html>"));
        driver.title.should == "OpenedWindow";
        driver.window.close();
        driver.window.switchTo(original);
        driver.window.handle.should == original;
        driver.window.handles.length.should == 1;
    }

    @Name("click updates button text") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><button id='btn' onclick='this.textContent=\"clicked\"'>click</button></body></html>"
        ));
        driver.find(By.css("#btn")).click();
        driver.find(By.css("#btn")).text.should == "clicked";
    }

    @Name("sendKeys sets input value") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><input id='field' value='initial'></body></html>"
        ));
        driver.find(By.css("#field")).clear();
        driver.find(By.css("#field")).sendKeys("abc");
        driver.find(By.css("#field")).property("value").should == "abc";
    }

    @Name("clear empties input field") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><input id='field' value='prefilled'></body></html>"
        ));
        driver.find(By.css("#field")).clear();
        driver.find(By.css("#field")).property("value").should == "";
    }

    @Name("nested element find") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><div id='outer'><span id='inner'>nested</span></div></body></html>"
        ));
        Element outer = driver.find(By.css("#outer"));
        outer.find(By.css("#inner")).text.should == "nested";
    }

    @Name("cssValue returns style value") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><p id='text' style='color:red;'>styled</p></body></html>"
        ));
        driver.find(By.css("#text")).cssValue("color").length.shouldBeGreaterThan(0);
    }

    @Name("stale element access throws") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><input id='stale' value='old'></body></html>"
        ));
        Element element = driver.find(By.css("#stale"));
        driver.refresh();

        element.attribute("value").shouldThrow!StaleElementReferenceException;
    }

    @Name("selected reflects checkbox state") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><input id='checked' type='checkbox' checked>"
            ~"<input id='unchecked' type='checkbox'></body></html>"
        ));
        driver.find(By.css("#checked")).selected.should == true;
        driver.find(By.css("#unchecked")).selected.should == false;
    }

    @Name("enabled reflects element state") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><input id='disabled' disabled><input id='enabled'></body></html>"
        ));
        driver.find(By.css("#disabled")).enabled.should == false;
        driver.find(By.css("#enabled")).enabled.should == true;
    }

    @Name("driver findAll preserves order and returns empty results") @Serial
    unittest
    {
        driver.go(dataUri(
            "<html><body><p class='item'>first</p><p class='item'>second</p></body></html>"
        ));

        Element[] elements = driver.findAll(By.css(".item"));
        elements.length.should == 2;
        elements[0].text.should == "first";
        elements[1].text.should == "second";
        driver.findAll(By.css(".missing")).length.should == 0;
    }

    @Name("element findAll stays within descendant scope") @Serial
    unittest
    {
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
    }

    @Name("frame switch by index") @Serial
    unittest
    {
        string inner = "<p id='inner'>inside</p>";
        string html = "<html><body>"~
            "<p id='top'>top</p>"~
            "<iframe id='frame1' srcdoc=\""~inner~"\"></iframe>"~
            "</body></html>";

        driver.go(dataUri(html));
        driver.frame.switchTo(0);
        driver.find(By.css("#inner")).text.should == "inside";
    }

    @Name("frame switch by element") @Serial
    unittest
    {
        string iframeHtml = "<p id='nested'>nested</p>";
        string html = "<html><body><iframe id='frame1' srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

        driver.go(dataUri(html));
        Element iframe = driver.find(By.css("iframe"));
        driver.frame.switchTo(iframe);
        driver.find(By.css("#nested")).text.should == "nested";
    }

    @Name("frame switch to parent") @Serial
    unittest
    {
        string iframeHtml = "<p id='child'>child</p>";
        string html = "<html><body><p id='parent'>parent</p>"~
            "<iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

        driver.go(dataUri(html));
        driver.frame.switchTo(0);
        driver.find(By.css("#child")).text.should == "child";
        driver.frame.switchToParent();
        driver.find(By.css("#parent")).text.should == "parent";
    }

    @Name("frame switch to top") @Serial
    unittest
    {
        string iframeHtml = "<p id='deep'>deep</p>";
        string html = "<html><body><p id='surface'>surface</p>"~
            "<iframe srcdoc=\""~iframeHtml~"\"></iframe></body></html>";

        driver.go(dataUri(html));
        driver.find(By.css("#surface")).text.should == "surface";
        driver.frame.switchTo(0);
        driver.find(By.css("#deep")).text.should == "deep";
        driver.frame.switchTo();
        driver.find(By.css("#surface")).text.should == "surface";
    }

    @Name("execute returns document title") @Serial
    unittest
    {
        driver.go(dataUri("<html><title>ScriptTest</title><body></body></html>"));
        driver.execute!string("return document.title;").should == "ScriptTest";
    }

    @Name("execute returns element count") @Serial
    unittest
    {
        driver.go(dataUri("<html><body><p id='count'>3</p></body></html>"));
        driver.execute!long("return document.getElementsByTagName('p').length;").should == 1;
    }

    @Name("execute returns boolean") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        driver.execute!bool("return true;").should == true;
    }

    @Name("execute returns element") @Serial
    unittest
    {
        driver.go(dataUri("<html><body><a id='link'>test</a></body></html>"));
        driver.execute!Element("return document.getElementById('link');").tagName.should == "a";
    }

    @Name("execute passes arguments") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        driver.execute!string(
            "return arguments[0] + arguments[1];",
            JSONValue([JSONValue("Hello, "), JSONValue("World!")])
        ).should == "Hello, World!";
    }

    @Name("execute throws on script error") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        driver.execute("return nonExistentFunction();").shouldThrow!JavaScriptException;
    }

    @Name("execute returns string array") @Serial
    unittest
    {
        driver.go(dataUri("<html><body></body></html>"));
        string[] values = driver.execute!(string[])("return ['zero', 'one', 'two'];");
        values.length.should == 3;
        values[0].should == "zero";
        values[1].should == "one";
        values[2].should == "two";
    }

    @Name("roots returns primary document first") @Serial
    unittest
    {
        driver.go(dataUri("<html><body><p>hello</p></body></html>"));
        Root[] roots = driver.roots();
        roots.length.shouldBeGreaterThan(0);
        roots[0].type.should == RootType.Primary;
    }

    @Name("roots discovers iframe as embedded") @Serial
    unittest
    {
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
    }

    @Name("embedded root find searches inside iframe") @Serial
    unittest
    {
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
    }

    @Name("element shadowRoot returns shadow root") @Serial
    unittest
    {
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
        Root shadow = host.shadowRoot();
        shadow.type.should == RootType.Shadow;
        shadow.find(By.css("#shady")).text.should == "shadow";
    }

    @Name("roots discovers open shadow root") @Serial
    unittest
    {
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
    }

    @Name("shadowRoot throws when absent") @Serial
    unittest
    {
        driver.go(dataUri("<html><body><div id='plain'>no shadow</div></body></html>"));
        Element plain = driver.find(By.css("#plain"));
        plain.shadowRoot().shouldThrow!NoSuchShadowRootException;
    }

    @Name("shadow root findAll preserves order and returns empty results") @Serial
    unittest
    {
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
    }

    @Name("embedded root findAll preserves order") @Serial
    unittest
    {
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
    }
}

