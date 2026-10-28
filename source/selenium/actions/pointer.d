/// W3C pointer input source types, move origins, and button constants.
module selenium.actions.pointer;

/// Pointer input source types.
enum PointerType : string
{
    /// Mouse pointer, the W3C default.
    Mouse = "mouse",
    /// Pen or stylus pointer.
    Pen = "pen",
    /// Touch pointer.
    Touch = "touch",
}

/// Move origins for pointer actions.
enum Origin : string
{
    /// Relative to the top-left corner of the viewport, the W3C default.
    Viewport = "viewport",
    /// Relative to the pointer's current position.
    Pointer = "pointer",
}

/// Button constants for pointer actions.
enum Button : int
{
    /// The primary button, usually the left mouse button.
    Primary = 0,
    /// The auxiliary button, usually the middle mouse button or wheel click.
    Auxiliary = 1,
    /// The secondary button, usually the right mouse button.
    Secondary = 2,
}
