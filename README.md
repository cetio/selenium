selenium.d
==========

selenium.d is a D library for controlling browsers via the WebDriver protocol.

## Setup

Install a WebDriver server (e.g. `chromedriver`, `geckodriver`) and ensure it is on your `PATH`.

## Usage

```d
import selenium;

// Zero-config: auto-detects Chrome, launches server, creates session
Driver driver = Driver.start();
scope(exit) driver.quit();

driver.url("http://example.com");
assert(driver.url == "https://example.com/");

Element heading = driver.findOne!"tag"("h1");
assert(heading.text == "Example Domain");

// Scoped element search
Element link = heading.findOne!"xpath"("following-sibling::p/a");
link.click();
```

### Explicit browser selection

```d
Driver driver = Driver.start(DriverType.Chrome);
Driver driver = Driver.start(DriverType.Firefox, "/usr/bin/geckodriver");
```

### Page objects

```d
class LoginPage : Page
{
    this(Driver driver) { super(driver); }

    override bool isPresent()
    {
        return driver.findOne!"id"("login-form") !is null;
    }

    void login(string username, string password)
    {
        driver.findOne!"id"("username").sendKeys(username);
        driver.findOne!"id"("password").sendKeys(password);
        driver.findOne!"id"("submit").click();
    }
}
```

## Locator strategies

Compile-time validated strategies:
```d
driver.findOne!"id"("foo");
driver.findOne!"css"(".bar");
driver.findOne!"xpath"("//div[@class='baz']");
```

Runtime strategies via `ElementLocator`:
```d
driver.findOne(byId("foo"));
driver.findOne(byCss(".bar"));
```

## Running tests

```bash
dub test
```

Dynamic integration tests require a WebDriver server (e.g. `chromedriver`) on `PATH`. Static tests run without any external dependencies.
