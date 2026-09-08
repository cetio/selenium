# Elements

An `Element` is a session-scoped handle to a DOM node. Every operation sends a WebDriver command through the owning `Driver`. If the node is detached, commands can throw `StaleElementReferenceException`.

For upstream concepts, see the [official Selenium element documentation](https://www.selenium.dev/documentation/webdriver/elements/).

## Locators

`By` pairs a W3C location strategy with a selector. The current helpers are:

| Helper | Strategy |
| --- | --- |
| `By.css(selector)` | CSS selector. |
| `By.xpath(expression)` | XPath expression. |
| `By.tagName(name)` | Tag name. |
| `By.linkText(text)` | Anchor with exact visible text. |
| `By.partialLinkText(text)` | Anchor containing the text. |

There is no `By.id` helper. Use a CSS ID selector such as `By.css("#submit")`.

```d
Element button = driver.find(By.css("#submit"));
Element[] links = driver.findAll(By.tagName("a"));
```

`find` throws `NoSuchElementException` when no element matches. `findAll` returns an empty array.

## State and Geometry

| Member | Purpose |
| --- | --- |
| `text` | Rendered visible text. |
| `tagName` | Lowercased tag name. |
| `attribute(name)` | HTML attribute value. |
| `property(name)` | Live DOM property value. |
| `cssValue(name)` | Computed CSS value. |
| `size` | Width and height as `Size`. |
| `position` | Top-left coordinates as `Position`. |
| `selected` | Whether an option or checkable input is selected. |
| `enabled` | Whether the element is enabled. |
| `screenshot` | Base64 PNG of the element. |

```d
Element input = driver.find(By.css("input[name='username']"));

writeln(input.attribute("placeholder"));
writeln(input.property("value"));
writeln(input.enabled);
writeln(input.size.width);
```

## Interaction

| Member | Purpose |
| --- | --- |
| `click()` | Click the element. |
| `sendKeys(text...)` | Concatenate and type one or more strings character by character. |
| `clear()` | Clear an editable element. |

```d
Element form = driver.find(By.tagName("form"));
Element input = form.find(By.css("input[name='username']"));

input.clear();
input.sendKeys("alice");
form.find(By.css("button[type='submit']")).click();
```

## Descendant Search

Calling `find` or `findAll` on an element restricts the search to its descendants:

```d
Element table = driver.find(By.css("#data"));
Element[] rows = table.findAll(By.tagName("tr"));
Element firstCell = table.find(By.tagName("td"));
```

The browser's implicit timeout is synchronized before descendant searches.

## Shadow Roots

`element.shadowRoot` requests the element's W3C shadow-root reference. It throws `NoSuchShadowRootException` when no shadow root exists. The returned `Root` supports `find` and `findAll` through the W3C shadow endpoints.

```d
Element host = driver.find(By.css("my-component"));
Root shadow = host.shadowRoot;
Element button = shadow.find(By.css("button"));
```

Only open shadow roots can be discovered by `driver.roots`. A directly returned root records open and complete state flags.

## Serialization

`element.toJSON()` returns the W3C element-reference object required when passing the element to commands such as frame switching. Reference IDs are opaque and valid only within the owning session.
