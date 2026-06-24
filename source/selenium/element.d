/// Element locators and the remote element handle for interaction.
module selenium.element;

import selenium.bridge : Bridge;
import selenium.driver : Driver;
import selenium.root : Root, RootState, RootType;

import std.array : join;
import std.conv : to;
import std.json : JSONValue;
import std.net.curl : HTTP;

/// A W3C location strategy paired with the selector value to match against.
struct By
{
    /// The location strategy name sent as the `using` field.
    string using;
    /// The selector expression interpreted according to `using`.
    string value;

    /// Locates elements by CSS selector.
    static By css(string value)
        => By("css selector", value);

    /// Locates elements by tag name.
    static By tagName(string value)
        => By("tag name", value);

    /// Locates anchors whose visible text equals the value.
    static By linkText(string value)
        => By("link text", value);

    /// Locates anchors whose visible text contains the value.
    static By partialLinkText(string value)
        => By("partial link text", value);

    /// Locates elements by XPath expression.
    static By xpath(string value)
        => By("xpath", value);

    /// Serializes the strategy into the `{using, value}` locator payload.
    JSONValue toJSON()
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["using"] = using;
        ret["value"] = value;
        return ret;
    }
}

/// A width and height pair in CSS pixels.
struct Size
{
    /// Width in CSS pixels.
    long width;
    /// Height in CSS pixels.
    long height;
}

/// A viewport coordinate pair in CSS pixels.
struct Position
{
    /// Horizontal offset in CSS pixels.
    long x;
    /// Vertical offset in CSS pixels.
    long y;
}

/// A handle to a remote element, identified by its W3C element reference.
///
/// Every method issues a request against the owning driver's session, so a handle
/// is only valid while that element remains attached to the DOM.
class Element
{
private:
    /// Builds an element-scoped endpoint path from a suffix.
    string path(string suffix)
        => "/element/"~id~suffix;

public:
    /// The driver whose session owns this element.
    Driver driver;
    /// The opaque W3C element reference returned by the server.
    string id;

    /**
     * Constructs an element handle.
     *
     * Params:
     *  driver = The owning driver session.
     *  id = The W3C element reference.
     */
    this(Driver driver, string id)
    {
        this.driver = driver;
        this.id = id;
    }

    /// The rendered, visible text of the element.
    string text() => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/text"));
    /// The lowercased tag name of the element.
    string tagName() => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/name"));
    /// The value of the named HTML attribute as it appears in markup.
    string attribute(string name) => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/attribute/"~name));
    /// The value of the named live DOM property, which may differ from the markup attribute.
    string property(string name) => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/property/"~name));
    /// The computed value of the named CSS property.
    string cssValue(string property)
        => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/css/"~property));

    /// The element bounding rectangle as a width and height pair.
    Size size() => driver.bridge.request!Size(driver.id, HTTP.Method.get, path("/rect"));
    /// The element bounding rectangle as a top-left coordinate pair.
    Position position() => driver.bridge.request!Position(driver.id, HTTP.Method.get, path("/rect"));
    /// Whether the element is currently selected, applicable to options and checkable inputs.
    bool selected() => driver.bridge.request!bool(driver.id, HTTP.Method.get, path("/selected"));
    /// Whether the element is enabled rather than disabled.
    bool enabled() => driver.bridge.request!bool(driver.id, HTTP.Method.get, path("/enabled"));

    /// Clicks the element.
    void click() => driver.bridge.request!void(driver.id, HTTP.Method.post, path("/click"));
    /**
     * Types the given key sequences into the element.
     *
     * Each argument is concatenated and dispatched character by character so that
     * key handlers fire per keystroke.
     *
     * Params:
     *  keys = One or more strings to type in order.
     */
    void sendKeys(string[] keys...)
    {
        JSONValue[] value;
        foreach (key; keys)
            foreach (dchar ch; key)
                value ~= JSONValue(ch.to!string);

        driver.bridge.request!void(driver.id, HTTP.Method.post, path("/value"), [
            "text": JSONValue(keys.join()),
            "value": JSONValue(value),
        ]);
    }
    /// Clears the value of an editable element.
    void clear() => driver.bridge.request!void(driver.id, HTTP.Method.post, path("/clear"));
    /// A base64 PNG screenshot of the element.
    string screenshot() => driver.bridge.request!string(driver.id, HTTP.Method.get, path("/screenshot"));

    /**
     * Finds the first descendant matching the locator.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  A handle to the matched descendant.
     *
     * Throws:
     *  NoSuchElementException if no descendant matches.
     */
    Element find(By by)
    {
        driver.bridge.ensureTimeoutsSynced(driver.id, driver.browser);

        JSONValue resp = driver.bridge.request(driver.id, HTTP.Method.post, path("/element"), by.toJSON());
        return new Element(driver, Bridge.parseElementId(resp));
    }

    /**
     * Finds every descendant matching the locator.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  Handles to all matched descendants, or an empty array if none match.
     */
    Element[] findAll(By by)
    {
        driver.bridge.ensureTimeoutsSynced(driver.id, driver.browser);

        JSONValue resp = driver.bridge.request(driver.id, HTTP.Method.post, path("/elements"), by.toJSON());
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(resp))
            ret ~= new Element(driver, eid);
        return ret;
    }

    /**
     * Returns the shadow root attached to this element, if any.
     *
     * Throws:
     *  NoSuchShadowRootException if the element does not have a shadow root.
     */
    Root shadowRoot()
    {
        JSONValue resp = driver.bridge.request(driver.id, HTTP.Method.get, path("/shadow"));
        string shadowId = Bridge.parseShadowId(resp);
        return new Root(driver, shadowId, RootType.Shadow, RootState.Open | RootState.Complete);
    }

    /// Serializes the element into the W3C element reference object.
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret[Bridge.W3C_KEY] = JSONValue(id);
        return ret;
    }
}
