/// Root abstractions for the primary document, iframes, and shadow roots.
module selenium.root;

import selenium.bridge : Bridge;
import selenium.driver : Driver;
import selenium.element : Element;
import selenium.locator : By;

import std.json : JSONValue;

/// The kind of root represented by a `Root` handle.
enum RootType : string
{
    /// The top-level document root.
    Primary = "primary",
    /// An iframe element root.
    Embedded = "embedded",
    /// A shadow-root root.
    Shadow = "shadow",
}

/// The lifecycle and accessibility state of a `Root`.
///
/// Readiness flags (`Uninitialized` through `Complete`) describe the state.
///
/// `Open` and `Closed` are shadow-root mode flags. A shadow root therefore carries one
/// readiness bit ORed with its mode bit.
///
/// `Loaded` is reserved for a distinct loaded state but is not currently
/// produced by `Driver.roots`, and `Closed` is (usually) undiscoverable through
/// `Driver.roots` because closed shadow roots have no `shadowRoot` property.
enum RootState : uint
{
    /// No state flags are set.
    None = 0,
    /// The document has not started loading, or its state could not be read.
    Uninitialized = 1,
    /// The document is still loading.
    Loading = 2,
    /// Reserved for a loaded document state.
    Loaded = 4,
    /// The document has parsed and is interactive, but subresources may still load.
    Interactive = 8,
    /// The document and its subresources have finished loading.
    Complete = 16,
    /// The shadow root is open and accessible through `element.shadowRoot`.
    Open = 32,
    /// The shadow root is closed.
    Closed = 64,
}

/// A handle to a searchable root context within the DOM.
///
/// `Primary` represents the top-level document, `Embedded` represents an
/// iframe element, and `Shadow` represents a shadow root. Only `find` and
/// `findAll` are supported, matching the subset of W3C commands valid on
/// shadow roots.
class Root
{
private:
    RootType _type;
    RootState _state;

public:
    /// The driver whose session owns this root.
    Driver driver;
    /// The opaque W3C reference. For `Primary` this is empty.
    string id;

    /**
     * Constructs a root handle.
     *
     * Params:
     *  driver = The owning driver session.
     *  id = The W3C element or shadow root reference.
     *  type = The kind of root.
     *  state = The current state bitmask.
     */
    this(Driver driver, string id, RootType type, RootState state)
    {
        this.driver = driver;
        this.id = id;
        this._type = type;
        this._state = state;
    }

    /// The root type.
    RootType type() => _type;
    /// The root state bitmask. See `RootState` for details.
    RootState state() => _state;

    /**
     * Finds the first element matching the locator within this root.
     *
     * For `Embedded` roots the current frame is switched to the iframe before
     * searching. For `Primary` roots the frame is reset to the top-level first.
     * The driver remains in the resulting context after the call.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  A handle to the matched element.
     *
     * Throws:
     *  NoSuchElementException if no element matches.
     *  WebDriverException subtypes for other server or connection failures.
     */
    Element find(By by)
    {
        if (_type == RootType.Primary)
            driver.frame.switchTo();
        else if (_type == RootType.Embedded)
        {
            driver.frame.switchTo();
            driver.frame.switchTo(new Element(driver, id));
        }

        string path = _type == RootType.Shadow 
            ? "/shadow/"~id~"/element" 
            : "/element";
        return new Element(driver, Bridge.parseElementId(driver.bridge.post(driver.id, path, by.toJSON())));
    }

    /**
     * Finds every element matching the locator within this root.
     *
     * For `Embedded` roots the current frame is switched to the iframe before
     * searching. For `Primary` roots the frame is reset to the top-level first.
     * The driver remains in the resulting context after the call.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  Handles to all matched elements, or an empty array if none match.
     *
     * Throws:
     *  WebDriverException subtypes for selector, frame, session, or connection failures.
     */
    Element[] findAll(By by)
    {
        if (_type == RootType.Primary)
            driver.frame.switchTo();
        else if (_type == RootType.Embedded)
        {
            driver.frame.switchTo();
            driver.frame.switchTo(new Element(driver, id));
        }

        string path = _type == RootType.Shadow 
            ? "/shadow/"~id~"/elements" 
            : "/elements";
        Element[] ret;
        foreach (eid; Bridge.parseElementIds(driver.bridge.post(driver.id, path, by.toJSON())))
            ret ~= new Element(driver, eid);
        return ret;
    }

    /**
     * Serializes the root into the appropriate W3C reference object.
     *
     * `Primary` roots serialize to an empty object.
     *
     * Returns: The W3C element, shadow-root reference, or empty object if primary.
     */
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        final switch (_type)
        {
            case RootType.Primary:
                break;
            case RootType.Embedded:
                ret[Bridge.W3C_KEY] = JSONValue(id);
                break;
            case RootType.Shadow:
                ret[Bridge.SHADOW_KEY] = JSONValue(id);
                break;
        }
        return ret;
    }
}
