# Selenium-SDK

[![License](https://img.shields.io/badge/License-AGPL%20v3-blue)](LICENSE.txt)

Selenium-SDK is a D library for browser automation via the WebDriver protocol. It manages driver lifecycle, element interaction, JavaScript execution, and browser options without requiring external language bindings.

## Features

- **Driver Lifecycle**: Start, quit, and auto-detect WebDriver executables on `PATH` for Chrome, Firefox, Edge, and Safari.
- **Navigation**: Navigate, go back/forward, refresh, and read page title and URL.
- **Element Search**: Find single or multiple elements by CSS selector, XPath, tag name, or name. Search globally or within an existing element.
- **Element Interaction**: Click, send keys, clear, submit, read text and attributes, and check enabled or displayed state.
- **JavaScript Execution**: Execute arbitrary scripts with typed return values.
- **Browser Options**: Configure all browsers using their `Browser` classes, (ie: `Chrome`).
- **Window Management**: Maximize, resize, enumerate handles, and close windows.

## Usage

`dub add selenium-sdk`

Install a WebDriver server and ensure it is on your `PATH` (e.g. `chromedriver`, `geckodriver`, `msedgedriver`, or `safaridriver`).

### Driver Lifecycle

`Driver.start` auto-detects the executable on `PATH` if you do not provide one.

```d
import selenium.driver;

Driver driver = Driver.start();
scope (exit) driver.quit();
```

Pin to a specific browser:

```d
import selenium.driver;
import selenium.browser.chrome : defaultChrome;

Driver driver = Driver.start(defaultChrome);
```

### Navigation

```d
driver.navigate("https://example.com");
writeln(driver.title);
writeln(driver.url);

driver.back();
driver.forward();
driver.refresh();
```

### Finding Elements

```d
import selenium.driver;
import selenium.element : Locator;

Element button = driver.find(Locator.CssSelector, "#submit");
Element[] items = driver.findAll(Locator.XPath, "//div[@class='item']");

// Search inside an element
Element form = driver.find(Locator.TagName, "form");
Element input = form.find(Locator.Name, "username");
```

### Interacting With Elements

```d
input.click();
input.sendKeys("hello");
input.clear();
input.submit();

writeln(input.text);
writeln(input.attribute("placeholder"));
writeln(input.enabled);
writeln(input.displayed);
```

### JavaScript Execution

```d
int result = driver.execute!int("return arguments[0] + arguments[1];");
```

### Window Management

```d
import selenium.element : Size;

driver.maximize();
driver.windowSize = Size(1920, 1080);

string[] handles = driver.windowHandles();
driver.closeWindow();
```

## License

Selenium-SDK is licensed under [AGPL-3.0](LICENSE.txt).

