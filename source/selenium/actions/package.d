/// W3C Actions framework: input sources, action items, and the per-session builder.
module selenium.actions;

public import selenium.actions.key : Key;
public import selenium.actions.pointer : Button, Origin, PointerType;

import selenium.driver : Driver;
import selenium.element : Element;

import std.conv : to;
import std.json : JSONValue;

enum InputType : string
{
    /// A null input source, used only for pauses that align ticks across sources.
    None = "none",
    /// A keyboard input source.
    Key = "key",
    /// A pointer input source, such as a mouse, pen, or touch device.
    Pointer = "pointer",
    /// A wheel input source.
    Wheel = "wheel",
}

struct Action
{
    /// The action kind, such as `pause`, `keyDown`, or `pointerMove`.
    string type;
    /// The key code point for `keyDown` and `keyUp`.
    dchar value;
    /// The pointer button index for `pointerDown`, `pointerUp`, and `pointerCancel`.
    int button;
    /// The duration in milliseconds for `pause`, `pointerMove`, and `scroll`.
    long duration;
    /// The horizontal coordinate for `pointerMove` and `scroll`.
    long x;
    /// The vertical coordinate for `pointerMove` and `scroll`.
    long y;
    /// The horizontal scroll delta for `scroll`.
    long deltaX;
    /// The vertical scroll delta for `scroll`.
    long deltaY;
    /// The move origin for `pointerMove`, as a string or element reference object.
    JSONValue origin;

    /// A pause action that occupies one tick without changing device state.
    static Action pause(long duration)
    {
        Action ret;
        ret.type = "pause";
        ret.duration = duration;
        return ret;
    }

    /// A key press action.
    static Action keyDown(dchar value)
    {
        Action ret;
        ret.type = "keyDown";
        ret.value = value;
        return ret;
    }

    /// A key release action.
    static Action keyUp(dchar value)
    {
        Action ret;
        ret.type = "keyUp";
        ret.value = value;
        return ret;
    }

    /// A pointer button press action.
    static Action pointerDown(int button)
    {
        Action ret;
        ret.type = "pointerDown";
        ret.button = button;
        return ret;
    }

    /// A pointer button release action.
    static Action pointerUp(int button)
    {
        Action ret;
        ret.type = "pointerUp";
        ret.button = button;
        return ret;
    }

    /// A pointer move action to `x`, `y` relative to `origin`.
    static Action pointerMove(
        long x,
        long y,
        long duration,
        JSONValue origin
    )
    {
        Action ret;
        ret.type = "pointerMove";
        ret.x = x;
        ret.y = y;
        ret.duration = duration;
        ret.origin = origin;
        return ret;
    }

    /// A pointer cancel action that aborts an in-progress pointer interaction.
    static Action pointerCancel(int button)
    {
        Action ret;
        ret.type = "pointerCancel";
        ret.button = button;
        return ret;
    }

    /// A wheel scroll action starting at `x`, `y` by `deltaX` and `deltaY`.
    static Action scroll(
        long x,
        long y,
        long deltaX,
        long deltaY,
        long duration
    )
    {
        Action ret;
        ret.type = "scroll";
        ret.x = x;
        ret.y = y;
        ret.deltaX = deltaX;
        ret.deltaY = deltaY;
        ret.duration = duration;
        return ret;
    }

    /// Serializes the action into the W3C action item object.
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["type"] = JSONValue(type);

        final switch (type)
        {
            case "pause":
                ret["duration"] = JSONValue(duration);
                break;
            case "keyDown":
            case "keyUp":
                ret["value"] = JSONValue(to!string(value));
                break;
            case "pointerDown":
            case "pointerUp":
            case "pointerCancel":
                ret["button"] = JSONValue(button);
                break;
            case "pointerMove":
                ret["duration"] = JSONValue(duration);
                ret["origin"] = origin;
                ret["x"] = JSONValue(x);
                ret["y"] = JSONValue(y);
                break;
            case "scroll":
                ret["duration"] = JSONValue(duration);
                ret["x"] = JSONValue(x);
                ret["y"] = JSONValue(y);
                ret["deltaX"] = JSONValue(deltaX);
                ret["deltaY"] = JSONValue(deltaY);
                break;
        }

        return ret;
    }
}

/// A W3C input source and its ordered action items.
struct Source
{
    /// The input source type.
    InputType type;
    /// The opaque id identifying this source within a tick.
    string id;
    /// The pointer device kind, used only when `type` is `Pointer`.
    PointerType pointerType = PointerType.Mouse;
    /// The action items, one per tick.
    Action[] actions;

    /// Serializes the source into the W3C action source object.
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["type"] = JSONValue(cast(string)type);
        ret["id"] = JSONValue(id);

        if (type == InputType.Pointer)
        {
            JSONValue params = JSONValue.emptyObject;
            params["pointerType"] = JSONValue(cast(string)pointerType);
            ret["parameters"] = params;
        }

        JSONValue[] actionArray;
        foreach (action; actions)
            actionArray ~= action.toJSON();

        ret["actions"] = JSONValue(actionArray);
        return ret;
    }
}

/// A fluent builder for W3C action sequences scoped to one driver session.
///
/// Each method appends an action item to the appropriate input source. Sources
/// are created lazily on first use and keyed by id, so a single builder can
/// coordinate keyboard, pointer, and wheel devices across aligned ticks. The
/// W3C model aligns actions by tick index: the nth action of every source runs
/// concurrently, and shorter sources are padded with implicit pauses. Call
/// `perform` to dispatch the assembled sequence, or `release` to cancel every
/// pressed key and button.
class Actions
{
private:
    Driver driver;
    Source[] sources;

    /// Finds or creates the source of `type` with `id`, returning its index.
    size_t sourceIndex(InputType type, string id)
    {
        foreach (i, ref src; sources)
        {
            if (src.type == type && src.id == id)
                return i;
        }

        Source src;
        src.type = type;
        src.id = id;
        sources ~= src;
        return sources.length - 1;
    }

    /// Finds or creates the key source with `id`.
    size_t keyIndex(string id)
        => sourceIndex(InputType.Key, id);

    /// Finds or creates the pointer source with `id`, recording `pointerType`.
    size_t pointerIndex(string id, PointerType pointerType)
    {
        size_t i = sourceIndex(InputType.Pointer, id);
        sources[i].pointerType = pointerType;
        return i;
    }

    /// Finds or creates the wheel source with `id`.
    size_t wheelIndex(string id)
        => sourceIndex(InputType.Wheel, id);

public:
    /**
     * Constructs an action builder bound to a driver session.
     *
     * Params:
     *  driver = The session that will execute the assembled actions.
     */
    this(Driver driver)
    {
        this.driver = driver;
    }

    /**
     * Presses a key on the keyboard source.
     *
     * Params:
     *  key = The code point to press, either a printable character or a `Key`.
     *  id = The keyboard source id, defaulting to `keyboard`.
     */
    Actions keyDown(dchar key, string id = "keyboard")
    {
        sources[keyIndex(id)].actions ~= Action.keyDown(key);
        return this;
    }

    /**
     * Releases a key on the keyboard source.
     *
     * Params:
     *  key = The code point to release, either a printable character or a `Key`.
     *  id = The keyboard source id, defaulting to `keyboard`.
     */
    Actions keyUp(dchar key, string id = "keyboard")
    {
        sources[keyIndex(id)].actions ~= Action.keyUp(key);
        return this;
    }

    /**
     * Types a string by pressing and releasing each code point in order.
     *
     * Params:
     *  keys = The string to type, decoded as UTF-8 code points.
     *  id = The keyboard source id, defaulting to `keyboard`.
     */
    Actions sendKeys(dstring keys, string id = "keyboard")
    {
        size_t i = keyIndex(id);
        foreach (dchar ch; keys)
        {
            sources[i].actions ~= Action.keyDown(ch);
            sources[i].actions ~= Action.keyUp(ch);
        }

        return this;
    }

    /**
     * Presses a pointer button.
     *
     * Params:
     *  button = The button index, defaulting to the primary button.
     *  id = The pointer source id, defaulting to `mouse`.
     *  pointerType = The pointer device kind, defaulting to a mouse.
     */
    Actions pointerDown(int button = Button.Primary, string id = "mouse", PointerType pointerType = PointerType.Mouse)
    {
        sources[pointerIndex(id, pointerType)].actions ~= Action.pointerDown(button);
        return this;
    }

    /**
     * Releases a pointer button.
     *
     * Params:
     *  button = The button index, defaulting to the primary button.
     *  id = The pointer source id, defaulting to `mouse`.
     *  pointerType = The pointer device kind, defaulting to a mouse.
     */
    Actions pointerUp(int button = Button.Primary, string id = "mouse", PointerType pointerType = PointerType.Mouse)
    {
        sources[pointerIndex(id, pointerType)].actions ~= Action.pointerUp(button);
        return this;
    }

    /**
     * Moves the pointer to viewport coordinates.
     *
     * Params:
     *  x = The horizontal offset from the viewport origin.
     *  y = The vertical offset from the viewport origin.
     *  duration = The transition duration in milliseconds.
     *  id = The pointer source id, defaulting to `mouse`.
     *  pointerType = The pointer device kind, defaulting to a mouse.
     */
    Actions move(
        long x,
        long y,
        long duration = 0,
        string id = "mouse",
        PointerType pointerType = PointerType.Mouse
    )
    {
        JSONValue origin = JSONValue(cast(string)Origin.Viewport);
        sources[pointerIndex(id, pointerType)].actions ~= Action.pointerMove(x, y, duration, origin);
        return this;
    }

    /**
     * Moves the pointer relative to a named origin.
     *
     * Params:
     *  x = The horizontal offset from `origin`.
     *  y = The vertical offset from `origin`.
     *  origin = The reference point, either `Viewport` or `Pointer`.
     *  duration = The transition duration in milliseconds.
     *  id = The pointer source id, defaulting to `mouse`.
     *  pointerType = The pointer device kind, defaulting to a mouse.
     */
    Actions move(
        long x,
        long y,
        Origin origin,
        long duration = 0,
        string id = "mouse",
        PointerType pointerType = PointerType.Mouse
    )
    {
        JSONValue originValue = JSONValue(cast(string)origin);
        sources[pointerIndex(id, pointerType)].actions ~= Action.pointerMove(x, y, duration, originValue);
        return this;
    }

    /**
     * Moves the pointer to the center of an element, plus an optional offset.
     *
     * Params:
     *  element = The element whose center is the move origin.
     *  x = The horizontal offset from the element center.
     *  y = The vertical offset from the element center.
     *  duration = The transition duration in milliseconds.
     *  id = The pointer source id, defaulting to `mouse`.
     *  pointerType = The pointer device kind, defaulting to a mouse.
     */
    Actions move(
        Element element,
        long x = 0,
        long y = 0,
        long duration = 0,
        string id = "mouse",
        PointerType pointerType = PointerType.Mouse
    )
    {
        sources[pointerIndex(id, pointerType)].actions ~= Action.pointerMove(x, y, duration, element.toJSON());
        return this;
    }

    /**
     * Presses and releases a pointer button, producing a single click.
     *
     * Params:
     *  button = The button index, defaulting to the primary button.
     *  id = The pointer source id, defaulting to `mouse`.
     *  pointerType = The pointer device kind, defaulting to a mouse.
     */
    Actions click(int button = Button.Primary, string id = "mouse", PointerType pointerType = PointerType.Mouse)
    {
        size_t i = pointerIndex(id, pointerType);
        sources[i].actions ~= Action.pointerDown(button);
        sources[i].actions ~= Action.pointerUp(button);
        return this;
    }

    /**
     * Presses and releases a pointer button twice, producing a double click.
     *
     * Params:
     *  button = The button index, defaulting to the primary button.
     *  id = The pointer source id, defaulting to `mouse`.
     *  pointerType = The pointer device kind, defaulting to a mouse.
     */
    Actions doubleClick(int button = Button.Primary, string id = "mouse", PointerType pointerType = PointerType.Mouse)
    {
        size_t i = pointerIndex(id, pointerType);
        sources[i].actions ~= Action.pointerDown(button);
        sources[i].actions ~= Action.pointerUp(button);
        sources[i].actions ~= Action.pointerDown(button);
        sources[i].actions ~= Action.pointerUp(button);
        return this;
    }

    /**
     * Clicks the secondary button, producing a context click.
     *
     * Params:
     *  id = The pointer source id, defaulting to `mouse`.
     *  pointerType = The pointer device kind, defaulting to a mouse.
     */
    Actions contextClick(string id = "mouse", PointerType pointerType = PointerType.Mouse)
        => click(Button.Secondary, id, pointerType);

    /**
     * Scrolls a wheel input source by the given deltas.
     *
     * Params:
     *  x = The horizontal coordinate to start scrolling from.
     *  y = The vertical coordinate to start scrolling from.
     *  deltaX = The horizontal scroll distance.
     *  deltaY = The vertical scroll distance.
     *  duration = The scroll duration in milliseconds.
     *  id = The wheel source id, defaulting to `wheel`.
     */
    Actions scroll(
        long x,
        long y,
        long deltaX,
        long deltaY,
        long duration = 0,
        string id = "wheel"
    )
    {
        sources[wheelIndex(id)].actions ~= Action.scroll(x, y, deltaX, deltaY, duration);
        return this;
    }

    /**
     * Pauses a single input source for one tick.
     *
     * Params:
     *  duration = The pause duration in milliseconds.
     *  id = The source id, defaulting to a `none` source named `none`.
     */
    Actions pause(long duration, string id = "none")
    {
        sources[sourceIndex(InputType.None, id)].actions ~= Action.pause(duration);
        return this;
    }

    /**
     * Dispatches the assembled action sequence to the session.
     *
     * The sequence is sent as a single `POST /actions` request. The builder
     * remains usable after the call so further actions can be appended and
     * performed again.
     */
    Actions perform()
    {
        JSONValue payload = JSONValue.emptyObject;
        JSONValue[] sourceArray;
        foreach (src; sources)
            sourceArray ~= src.toJSON();

        payload["actions"] = JSONValue(sourceArray);
        driver.bridge.post!void(driver.id, "/actions", payload);
        return this;
    }

    /**
     * Releases every pressed key and pointer button on the session.
     *
     * Issues `DELETE /actions`, cancelling any input left in an intermediate
     * state by a previous `perform`.
     */
    void release() => driver.bridge.del!void(driver.id, "/actions");
}

/// Opens an action builder for a session, used as `driver.actions`.
Actions actions(Driver driver)
    => new Actions(driver);
