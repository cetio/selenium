/// Root abstractions for the primary document, iframes, and shadow roots.
module selenium.root;

import selenium.bridge : Bridge;
import selenium.driver : Driver;
import selenium.element : By, Element;

import std.json : JSONValue;

/// The kind of root represented by a `Root` handle.
enum RootType : string
{
    Primary = "primary",
    Embedded = "embedded",
    Shadow = "shadow",
}

/// The lifecycle and accessibility state of a `Root`.
enum RootState : uint
{
    None = 0,
    Uninitialized = 1,
    Loading = 2,
    Loaded = 4,
    Interactive = 8,
    Complete = 16,
    Open = 32,
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

    string _findPath() const
    {
        final switch (_type)
        {
            case RootType.Primary:
                return "/element";
            case RootType.Embedded:
                return "/element";
            case RootType.Shadow:
                return "/shadow/"~id~"/element";
        }
    }

    string _findAllPath() const
    {
        final switch (_type)
        {
            case RootType.Primary:
                return "/elements";
            case RootType.Embedded:
                return "/elements";
            case RootType.Shadow:
                return "/shadow/"~id~"/elements";
        }
    }

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

    /// The kind of root.
    RootType type() => _type;
    /// The current state bitmask.
    RootState state() => _state;

    /**
     * Finds the first element matching the locator within this root.
     *
     * For `Embedded` roots the current frame is temporarily switched to the
     * iframe and restored to its parent afterwards. Callers nested inside a
     * different frame context may be affected.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  A handle to the matched element.
     *
     * Throws:
     *  NoSuchElementException if no element matches.
     */
    Element find(By by)
    {
        driver.bridge.ensureTimeoutsSynced(driver.id, driver.browser);

        final switch (_type)
        {
            case RootType.Primary:
                JSONValue resp = driver.bridge.post(
                    driver.id,
                    _findPath,
                    by.toJSON()
                );
                return new Element(driver, Bridge.parseElementId(resp));

            case RootType.Embedded:
                Element iframe = new Element(driver, id);
                driver.frame.switchTo(iframe);
                JSONValue resp = driver.bridge.post(
                    driver.id,
                    _findPath,
                    by.toJSON()
                );
                return new Element(driver, Bridge.parseElementId(resp));
                
            case RootType.Shadow:
                JSONValue resp = driver.bridge.post(
                    driver.id,
                    _findPath,
                    by.toJSON()
                );
                return new Element(driver, Bridge.parseElementId(resp));
        }
    }

    /**
     * Finds every element matching the locator within this root.
     *
     * For `Embedded` roots the current frame is temporarily switched to the
     * iframe and restored to its parent afterwards. Callers nested inside a
     * different frame context may be affected.
     *
     * Params:
     *  by = The location strategy and selector.
     *
     * Returns:
     *  Handles to all matched elements, or an empty array if none match.
     */
    Element[] findAll(By by)
    {
        driver.bridge.ensureTimeoutsSynced(driver.id, driver.browser);

        final switch (_type)
        {
            case RootType.Primary:
                JSONValue resp = driver.bridge.post(
                    driver.id,
                    _findAllPath,
                    by.toJSON()
                );
                Element[] ret;
                foreach (eid; Bridge.parseElementIds(resp))
                    ret ~= new Element(driver, eid);
                return ret;
            case RootType.Embedded:
                Element iframe = new Element(driver, id);
                driver.frame.switchTo(iframe);
                JSONValue resp = driver.bridge.post(
                    driver.id,
                    _findAllPath,
                    by.toJSON()
                );
                Element[] ret;
                foreach (eid; Bridge.parseElementIds(resp))
                    ret ~= new Element(driver, eid);
                return ret;
            case RootType.Shadow:
                JSONValue resp = driver.bridge.post(
                    driver.id,
                    _findAllPath,
                    by.toJSON()
                );
                Element[] ret;
                foreach (eid; Bridge.parseElementIds(resp))
                    ret ~= new Element(driver, eid);
                return ret;
        }
    }

    /// Serializes the root into the appropriate W3C reference object.
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
