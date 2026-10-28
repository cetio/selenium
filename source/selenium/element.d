/// Element locators and the remote element handle for interaction.
module selenium.element;

import selenium.bridge : Bridge;
import selenium.driver : Driver;
import selenium.exception;
import selenium.root : Root, RootState, RootType;

import std.conv : to;
import std.json : JSONValue;
import std.string : toLower;

// TODO: Separate locator from element structure.

/// A W3C location strategy paired with the selector value to match against.
struct By
{

    /// The location strategy name sent as the `using` field.
    string using;
    /// The selector expression interpreted according to `using`.
    string value;

    /**
     * Constructs a locator.
     *
     * Params:
     *  using = The W3C location strategy name.
     *  value = The selector expression.
     *
     * Throws:
     *  InvalidSelectorException if the strategy is unknown, the value is
     *  empty, or an XPath value has unbalanced delimiters.
     */
    this(string using, string value)
    {
        validate(using, value);
        this.using = using;
        this.value = value;
    }

    /**
     * Locates elements by CSS selector.
     *
     * Throws:
     *  InvalidSelectorException if `value` is empty.
     */
    static By css(string value)
        => By("css selector", value);

    /**
     * Locates elements by tag name.
     *
     * Throws:
     *  InvalidSelectorException if `value` is empty.
     */
    static By tagName(string value)
        => By("tag name", value);

    /**
     * Locates anchors whose visible text equals the value.
     *
     * Throws:
     *  InvalidSelectorException if `value` is empty.
     */
    static By linkText(string value)
        => By("link text", value);

    /**
     * Locates anchors whose visible text contains the value.
     *
     * Throws:
     *  InvalidSelectorException if `value` is empty.
     */
    static By partialLinkText(string value)
        => By("partial link text", value);

    /**
     * Locates elements by XPath expression.
     *
     * Throws:
     *  InvalidSelectorException if `value` is empty or has unbalanced delimiters.
     */
    static By xpath(string value)
        => By("xpath", value);

    /**
     * Serializes the strategy into the `{using, value}` locator payload.
     *
     * Returns: The locator payload.
     */
    JSONValue toJSON()
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["using"] = using;
        ret["value"] = value;
        return ret;
    }

private:
    static void validate(string using, string value)
    {
        switch (using)
        {
            case "css selector", "link text", "partial link text", "tag name", "xpath":
                break;
            default:
                throw new InvalidSelectorException("Unknown location strategy: "~using);
        }

        if (value.length == 0)
            throw new InvalidSelectorException("Selector value must not be empty.");

        if (using != "xpath")
            return;

        dchar quote = 0;
        dchar[] delimiters;
        foreach (dchar character; value)
        {
            if (quote != 0)
            {
                if (character == quote)
                    quote = 0;
                continue;
            }

            if (character == '\'' || character == '"')
            {
                quote = character;
                continue;
            }

            switch (character)
            {
                case '[', '(':
                    delimiters ~= character;
                    break;
                case ']':
                    if (delimiters.length == 0 || delimiters[$-1] != '[')
                        throw new InvalidSelectorException("XPath expression has unbalanced delimiters.");
                    delimiters = delimiters[0..$-1];
                    break;
                case ')':
                    if (delimiters.length == 0 || delimiters[$-1] != '(')
                        throw new InvalidSelectorException("XPath expression has unbalanced delimiters.");
                    delimiters = delimiters[0..$-1];
                    break;
                default:
                    break;
            }
        }

        if (quote != 0 || delimiters.length > 0)
            throw new InvalidSelectorException("XPath expression has unbalanced delimiters.");
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

/// A position and size pair in pixels, used for window and element rectangles.
struct Rect
{
    /// Horizontal offset in pixels.
    long x;
    /// Vertical offset in pixels.
    long y;
    /// Width in pixels.
    long width;
    /// Height in pixels.
    long height;
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

    /**
     * The rendered, visible text of the element.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a string.
     */
    string text() => driver.bridge.get!string(driver.id, path("/text"));
    /**
     * The lowercased tag name of the element.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a string.
     */
    string tagName() => driver.bridge.get!string(driver.id, path("/name")).toLower();
    /**
     * The value of the named HTML attribute as it appears in markup.
     *
     * Params:
     *  name = The attribute name, interpolated into the URL path without encoding.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a string.
     */
    string attribute(string name) => driver.bridge.get!string(driver.id, path("/attribute/"~name));
    /**
     * The value of the named live DOM property, which may differ from the markup attribute.
     *
     * Params:
     *  name = The property name, interpolated into the URL path without encoding.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a string.
     */
    string property(string name) => driver.bridge.get!string(driver.id, path("/property/"~name));
    /**
     * The computed value of the named CSS property.
     *
     * Params:
     *  property = The CSS property name, interpolated into the URL path without encoding.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a string.
     */
    string cssValue(string property)
        => driver.bridge.get!string(driver.id, path("/css/"~property));

    /**
     * The computed WAI-ARIA role of the element, or an empty string when none applies.
     *
     * Support varies by driver; Chromium-based drivers implement the endpoint.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a string.
     */
    string computedRole()
        => driver.bridge.get!string(driver.id, path("/computedrole"));
    /**
     * The computed accessible name of the element, or an empty string when none applies.
     *
     * Support varies by driver; Chromium-based drivers implement the endpoint.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a string.
     */
    string computedLabel()
        => driver.bridge.get!string(driver.id, path("/computedlabel"));

    /**
     * The element bounding rectangle as a width and height pair.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response shape is invalid.
     */
    Size size()
    {
        JSONValue value = driver.bridge.unwrapAndParse!JSONValue(driver.bridge.get(driver.id, path("/rect")));
        return Size(value["width"].get!long, value["height"].get!long);
    }

    /**
     * The element bounding rectangle as a top-left coordinate pair.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response shape is invalid.
     */
    Position position()
    {
        JSONValue value = driver.bridge.unwrapAndParse!JSONValue(driver.bridge.get(driver.id, path("/rect")));
        return Position(value["x"].get!long, value["y"].get!long);
    }

    /**
     * Whether the element is currently selected, applicable to options and checkable inputs.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a boolean.
     */
    bool selected() => driver.bridge.get!bool(driver.id, path("/selected"));
    /**
     * Whether the element is enabled.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  WebDriverException subtypes for connection or server failures.
     *  JSONException if the response is not a boolean.
     */
    bool enabled() => driver.bridge.get!bool(driver.id, path("/enabled"));

    /**
     * Clicks the element.
     *
     * Throws:
     *  ElementClickInterceptedException if another element intercepts the click.
     *  ElementNotInteractableException if the element cannot receive the click.
     *  StaleElementReferenceException if the element is detached.
     *  InvalidSessionIdException if the session is not active.
     *  WebDriverConnectionException if the request fails.
     *  WebDriverException subtypes mapped from server errors.
     */
    void click() => driver.bridge.post!void(driver.id, path("/click"));
    /**
     * Types the given key sequences into the element.
     *
     * Each argument is concatenated and dispatched character by character so that
     * key handlers fire per keystroke. Arguments may be strings of printable
     * characters or any `Key` values.
     *
     * Params:
     *  T = One or more `string` or `dchar`/`Key` arguments.
     *  args = The key sequences to type in order.
     *
     * Throws:
     *  ElementNotInteractableException if the element cannot receive input.
     *  InvalidElementStateException if the element is not editable.
     *  StaleElementReferenceException if the element is detached.
     *  InvalidSessionIdException if the session is not active.
     *  WebDriverConnectionException if the request fails.
     *  WebDriverException subtypes mapped from server errors.
     */
    void sendKeys(T...)(T args)
    {
        JSONValue[] value;
        string text;
        foreach (arg; args)
        {
            static if (is(typeof(arg) == string))
            {
                text ~= arg;
                foreach (dchar ch; arg)
                    value ~= JSONValue(ch.to!string);
            }
            else static if (is(typeof(arg) : dchar))
            {
                string s = (cast(dchar)arg).to!string;
                text ~= s;
                value ~= JSONValue(s);
            }
            else
                static assert(0, "sendKeys accepts string or dchar/Key, not "~typeof(arg).stringof);
        }

        driver.bridge.post!void(driver.id, path("/value"), JSONValue([
            "text": JSONValue(text),
            "value": JSONValue(value),
        ]));
    }
    /**
     * Clears the value of an editable element.
     *
     * Throws:
     *  ElementNotInteractableException if the element cannot receive input.
     *  InvalidElementStateException if the element is not editable.
     *  StaleElementReferenceException if the element is detached.
     *  InvalidSessionIdException if the session is not active.
     *  WebDriverConnectionException if the request fails.
     *  WebDriverException subtypes mapped from server errors.
     */
    void clear() => driver.bridge.post!void(driver.id, path("/clear"));
    /**
     * A base64 PNG screenshot of the element.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  InvalidSessionIdException if the session is not active.
     *  WebDriverConnectionException if the request fails.
     *  WebDriverException subtypes mapped from server errors.
     *  JSONException if the response is not a string.
     */
    string screenshot() => driver.bridge.get!string(driver.id, path("/screenshot"));

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
     *  InvalidSelectorException if the locator is rejected.
     *  StaleElementReferenceException if the element is detached.
     *  InvalidSessionIdException if the session is not active.
     *  WebDriverConnectionException if the request fails.
     *  WebDriverException subtypes mapped from server errors.
     */
    Element find(By by)
        => new Element(driver, Bridge.parseElementId(driver.bridge.post(driver.id, path("/element"), by.toJSON())));

    /**
     * Finds every descendant matching the locator.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  Handles to all matched descendants, or an empty array if none match.
     *
     * Throws:
     *  InvalidSelectorException if the locator is rejected.
     *  StaleElementReferenceException if the element is detached.
     *  InvalidSessionIdException if the session is not active.
     *  WebDriverConnectionException if the request fails.
     *  WebDriverException subtypes mapped from server errors.
     */
    Element[] findAll(By by)
    {
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(driver.bridge.post(driver.id, path("/elements"), by.toJSON())))
            ret ~= new Element(driver, eid);
        return ret;
    }

    /**
     * Returns the shadow root attached to this element.
     *
     * The returned root has `RootState.None`. 
     * Chromium and Firefox support this, but Safari is finicky.
     *
     * Returns: A handle to the shadow root.
     *
     * Throws:
     *  NoSuchShadowRootException if the element does not have a shadow root.
     *  DetachedShadowRootException if the shadow root is no longer attached.
     *  StaleElementReferenceException if the element is detached.
     *  InvalidSessionIdException if the session is not active.
     *  WebDriverConnectionException if the request fails.
     *  WebDriverException subtypes mapped from server errors.
     */
    Root shadowRoot()
    {
        string shadowId = Bridge.parseShadowId(driver.bridge.get(driver.id, path("/shadow")));
        if (shadowId is null)
            throw new NoSuchShadowRootException("Element does not have a shadow root.");

        return new Root(driver, shadowId, RootType.Shadow, RootState.None);
    }

    /**
     * Whether this element has a shadow root. False if no shadow root or detached.
     *
     * Returns: True if a shadow root is present.
     *
     * Throws:
     *  StaleElementReferenceException if the element is detached.
     *  InvalidSessionIdException if the session is not active.
     *  WebDriverConnectionException if the request fails.
     *  WebDriverException subtypes mapped from server errors.
     */
    bool hasShadowRoot()
    {
        try
            driver.bridge.get(driver.id, path("/shadow"));
        catch (NoSuchShadowRootException)
            return false;
        catch (DetachedShadowRootException)
            return false;

        return true;
    }

    /**
     * Serializes the element into the W3C element reference object.
     *
     * Returns: The W3C element reference.
     */
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret[Bridge.W3C_KEY] = JSONValue(id);
        return ret;
    }
}
