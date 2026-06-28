# Elements (WebDriver)

An `Element` is a handle to a node in the page. It is valid only while that node stays attached to the DOM; stale handles raise `StaleElementReferenceException`.

For the official Selenium documentation on elements, see https://www.selenium.dev/documentation/webdriver/elements/.

## Locators

The `By` struct pairs a location strategy with a selector. Pass it to `find` or `findAll` on a driver, element, or root.

| Locator | Strategy | Ruby equivalent |
| --- | --- | --- |
| `By.css(selector)` | CSS selector | `css: selector` |
| `By.xpath(expr)` | XPath expression | `xpath: expr` |
| `By.tagName(name)` | Tag name | `tag_name: name` |
| `By.linkText(text)` | Anchor with exact visible text | `link_text: text` |
| `By.partialLinkText(text)` | Anchor containing the text | `partial_link_text: text` |

```d
Element button = driver.find(By.css("#submit"));
Element[] links = driver.findAll(By.tagName("a"));
```

## Properties

| Member | Purpose |
| --- | --- |
| `text` | Rendered visible text. |
| `tagName` | Lowercased tag name. |
| `attribute(name)` | Markup attribute value. |
| `property(name)` | Live DOM property value, which may differ from the markup attribute. |
| `cssValue(name)` | Computed CSS value. |
| `size` | Bounding rectangle as a `Size` (width, height). |
| `position` | Bounding rectangle as a `Position` (x, y). |
| `selected` | Whether the element is selected, applicable to options and checkable inputs. |
| `enabled` | Whether the element is enabled rather than disabled. |
| `screenshot` | Base64 PNG of the element. |

```d
Element input = driver.find(By.css("input[name='username']"));

writeln(input.attribute("placeholder"));
writeln(input.property("value"));
writeln(input.enabled);
writeln(input.size.width);
```

In Ruby: `element.attribute('placeholder')`, `element.property('value')`, `element.enabled?`, `element.size`. The D version uses `property` where Ruby uses `property` and `attribute` where Ruby uses `attribute`, matching the W3C distinction between markup attributes and live DOM properties.

## Interaction

| Member | Purpose |
| --- | --- |
| `click()` | Click the element. |
| `sendKeys(text...)` | Type one or more strings into the element, character by character. |
| `clear()` | Clear the value of an editable element. |

```d
Element form = driver.find(By.tagName("form"));
Element input = form.find(By.css("input[name='username']"));

input.sendKeys("alice");
form.find(By.css("button[type='submit']")).click();
```

In Ruby: `element.send_keys('alice')`, `element.click`, `element.clear`. The D `sendKeys` is variadic, so you can pass multiple strings and they are concatenated in order.

## Scoped search

`find` and `findAll` on an element search only within that element's descendants.

```d
Element table = driver.find(By.id("data"));
Element[] rows = table.findAll(By.tagName("tr"));
Element firstCell = table.find(By.tagName("td"));
```

In Ruby: `element.find_elements(tag_name: 'tr')` and `element.find_element(tag_name: 'td')`.

## Shadow roots

`shadowRoot` returns the shadow root attached to an element, if any. The returned `Root` can be searched with `find` and `findAll` using the W3C shadow root endpoints.

```d
Element host = driver.find(By.css("my-component"));
Root shadow = host.shadowRoot;
Element inner = shadow.find(By.css("button"));
```

In Ruby: `element.shadow_root` and `shadow_root.find_element(css: 'button')`.
