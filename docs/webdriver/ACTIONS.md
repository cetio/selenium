---
layout: default
title: Actions
parent: WebDriver
nav_order: 5
permalink: /webdriver/actions/
---

# Actions

The Actions framework models the W3C Actions API: a sequence of input sources whose action items are aligned into ticks and executed concurrently. Each tick runs one action per source in parallel, and shorter sources are padded with implicit pauses.

`driver.actions` returns a fresh `Actions` builder bound to the session. Each method appends an action item to the appropriate input source, which is created lazily on first use and keyed by id. Call `perform` to dispatch the assembled sequence as a single `POST /actions` request, or `release` to cancel every pressed key and button with `DELETE /actions`.

```d
import selenium.actions;
import selenium.actions.key : Key;

driver.actions
    .keyDown(Key.Shift)
    .sendKeys("abc")
    .keyUp(Key.Shift)
    .perform();
```

For upstream concepts, see the [official Selenium actions documentation](https://www.selenium.dev/documentation/webdriver/actions/).

## Input Sources

Every action belongs to one of four W3C input source types:

| Type | Purpose |
| --- | --- |
| `none` | A null source used only for pauses that align ticks. |
| `key` | A keyboard input source. |
| `pointer` | A mouse, pen, or touch pointer. |
| `wheel` | A wheel input source for scrolling. |

Sources are created on first use and identified by an id string. The default ids are `keyboard`, `mouse`, and `wheel`. Pointer sources carry a `PointerType` (`Mouse`, `Pen`, or `Touch`) serialized as the `parameters.pointerType` field.

## Keyboard Actions

| Member | Action |
| --- | --- |
| `keyDown(key, id = "keyboard")` | Press a code point or `Key`. |
| `keyUp(key, id = "keyboard")` | Release a code point or `Key`. |
| `sendKeys(text, id = "keyboard")` | Press and release each code point in order. |

`Key` enumerates the non-printable code points in the Unicode Private Use Area defined by the WebDriver specification, such as `Key.Enter`, `Key.Shift`, `Key.ArrowLeft`, and `Key.F12`. Printable characters are passed directly.

```d
driver.actions
    .keyDown(Key.Control)
    .keyDown('a')
    .keyUp('a')
    .keyUp(Key.Control)
    .perform();
```

## Pointer Actions

| Member | Action |
| --- | --- |
| `pointerDown(button = Button.Primary, id = "mouse", pointerType = Mouse)` | Press a pointer button. |
| `pointerUp(button = Button.Primary, id = "mouse", pointerType = Mouse)` | Release a pointer button. |
| `move(x, y, duration = 0, id = "mouse", pointerType = Mouse)` | Move to viewport coordinates. |
| `move(x, y, origin, duration = 0, ...)` | Move relative to `Origin.Viewport` or `Origin.Pointer`. |
| `move(element, x = 0, y = 0, duration = 0, ...)` | Move to an element center plus an offset. |
| `click(button = Button.Primary, ...)` | Press and release a button. |
| `doubleClick(button = Button.Primary, ...)` | Press and release a button twice. |
| `contextClick(...)` | Click the secondary button. |

`Button` enumerates `Primary` (0), `Auxiliary` (1), and `Secondary` (2). The default move origin is the viewport.

```d
Element canvas = driver.find(By.css("#canvas"));
driver.actions
    .move(canvas, 10, 10)
    .click()
    .perform();
```

## Wheel Actions

| Member | Action |
| --- | --- |
| `scroll(x, y, deltaX, deltaY, duration = 0, id = "wheel")` | Scroll by deltas from a starting point. |

```d
driver.actions
    .scroll(0, 0, 0, 300)
    .perform();
```

## Pauses and Tick Alignment

`pause(duration, id = "none")` adds a pause action to a single source. Pauses occupy one tick without changing device state and are used to align concurrent sources.

```d
driver.actions
    .move(element)
    .pause(100, "mouse")
    .click()
    .perform();
```

## Dispatch and Release

| Member | Action |
| --- | --- |
| `perform()` | Send the assembled sequence as `POST /actions`. The builder remains usable. |
| `release()` | Cancel every pressed key and button with `DELETE /actions`. |

```d
driver.actions
    .keyDown(Key.Space)
    .perform();

scope (exit) driver.actions.release;
```
