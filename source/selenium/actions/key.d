/// W3C keyboard input source key code points for non-printable keys.
module selenium.actions.key;

/// Special key code points used by the W3C keyboard input source.
///
/// Printable characters are sent directly as their own code point. These values
/// occupy the Unicode Private Use Area so they never collide with real
/// characters, matching the code points defined by the WebDriver specification.
enum Key : dchar
{
    /// The null key, used to release every modifier.
    Null = '\uE000',
    /// The Cancel key.
    Cancel = '\uE001',
    /// The Help key.
    Help = '\uE002',
    /// The Backspace key.
    Backspace = '\uE003',
    /// The Tab key.
    Tab = '\uE004',
    /// The Clear key.
    Clear = '\uE005',
    /// The Return key.
    Return = '\uE006',
    /// The Enter key.
    Enter = '\uE007',
    /// The Shift modifier.
    Shift = '\uE008',
    /// The Control modifier.
    Control = '\uE009',
    /// The Alt modifier.
    Alt = '\uE00A',
    /// The Pause key.
    Pause = '\uE00B',
    /// The Escape key.
    Escape = '\uE00C',
    /// The Space key.
    Space = '\uE00D',
    /// The Page Up key.
    PageUp = '\uE00E',
    /// The Page Down key.
    PageDown = '\uE00F',
    /// The End key.
    End = '\uE010',
    /// The Home key.
    Home = '\uE011',
    /// The left arrow key.
    ArrowLeft = '\uE012',
    /// The up arrow key.
    ArrowUp = '\uE013',
    /// The right arrow key.
    ArrowRight = '\uE014',
    /// The down arrow key.
    ArrowDown = '\uE015',
    /// The Insert key.
    Insert = '\uE016',
    /// The Delete key.
    Delete = '\uE017',
    /// The Semicolon key.
    Semicolon = '\uE018',
    /// The Equals key.
    Equals = '\uE019',
    /// The numpad 0 key.
    Numpad0 = '\uE01A',
    /// The numpad 1 key.
    Numpad1 = '\uE01B',
    /// The numpad 2 key.
    Numpad2 = '\uE01C',
    /// The numpad 3 key.
    Numpad3 = '\uE01D',
    /// The numpad 4 key.
    Numpad4 = '\uE01E',
    /// The numpad 5 key.
    Numpad5 = '\uE01F',
    /// The numpad 6 key.
    Numpad6 = '\uE020',
    /// The numpad 7 key.
    Numpad7 = '\uE021',
    /// The numpad 8 key.
    Numpad8 = '\uE022',
    /// The numpad 9 key.
    Numpad9 = '\uE023',
    /// The numpad multiply key.
    Multiply = '\uE024',
    /// The numpad add key.
    Add = '\uE025',
    /// The numpad separator key.
    Separator = '\uE026',
    /// The numpad subtract key.
    Subtract = '\uE027',
    /// The numpad decimal key.
    Decimal = '\uE028',
    /// The numpad divide key.
    Divide = '\uE029',
    /// The F1 key.
    F1 = '\uE031',
    /// The F2 key.
    F2 = '\uE032',
    /// The F3 key.
    F3 = '\uE033',
    /// The F4 key.
    F4 = '\uE034',
    /// The F5 key.
    F5 = '\uE035',
    /// The F6 key.
    F6 = '\uE036',
    /// The F7 key.
    F7 = '\uE037',
    /// The F8 key.
    F8 = '\uE038',
    /// The F9 key.
    F9 = '\uE039',
    /// The F10 key.
    F10 = '\uE03A',
    /// The F11 key.
    F11 = '\uE03B',
    /// The F12 key.
    F12 = '\uE03C',
    /// The Meta modifier.
    Meta = '\uE03D',
    /// The Command key, an alias for `Meta`.
    Command = '\uE03D',
}
