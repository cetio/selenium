/// Page printing options and the W3C `/print` request body model.
module selenium.driver.print;

import selenium.exception : InvalidArgumentException;

import std.json : JSONValue;

/// Page orientation for printed output.
enum Orientation : string
{
    /// Taller than wide, the W3C default.
    Portrait = "portrait",
    /// Wider than tall.
    Landscape = "landscape",
}

/// Options for printing the current page to a PDF document.
struct PrintOptions
{
private:
    double _scale = 1.0;
    double _pageWidth = 8.5;
    double _pageHeight = 11.0;

public:
    /// Page orientation, defaulting to portrait.
    Orientation orientation = Orientation.Portrait;
    /// Whether to print background graphics, defaulting to false.
    bool background;
    /// Whether to shrink content to fit the page, defaulting to true.
    bool shrinkToFit = true;
    /// Page ranges to print.
    string[] pageRanges;

    /// Scale factor clamped to the range 0.1 through 2.0, defaulting to 1.0.
    @property double scale() const
        => _scale;

    /**
     * Sets the print scale.
     *
     * Params:
     *  val = The scale factor, clamped to the range 0.1 through 2.0.
     *
     * Throws:
     *  InvalidArgumentException if val is outside 0.1 through 2.0.
     */
    @property double scale(double val)
    {
        if (val < 0.1 || val > 2.0)
            throw new InvalidArgumentException("Print scale must be between 0.1 and 2.0.");
        return _scale = val;
    }

    /// Paper width in inches, defaulting to 8.5 (US Letter).
    @property double pageWidth() const
        => _pageWidth;

    /**
     * Sets the paper width.
     *
     * Params:
     *  val = The width in inches, must be positive.
     *
     * Throws:
     *  InvalidArgumentException if val is not positive.
     */
    @property double pageWidth(double val)
    {
        if (val <= 0)
            throw new InvalidArgumentException("Print page width must be positive.");
        return _pageWidth = val;
    }

    /// Paper height in inches, defaulting to 11.0 (US Letter).
    @property double pageHeight() const
        => _pageHeight;

    /**
     * Sets the paper height.
     *
     * Params:
     *  val = The height in inches, must be positive.
     *
     * Throws:
     *  InvalidArgumentException if val is not positive.
     */
    @property double pageHeight(double val)
    {
        if (val <= 0)
            throw new InvalidArgumentException("Print page height must be positive.");
        return _pageHeight = val;
    }

    /**
     * Serializes the options into the W3C `/print` request body.
     *
     * `pageRanges` is omitted when empty so the server prints every page.
     */
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["orientation"] = JSONValue(cast(string)orientation);
        ret["scale"] = JSONValue(_scale);
        ret["background"] = JSONValue(background);
        ret["pageWidth"] = JSONValue(_pageWidth);
        ret["pageHeight"] = JSONValue(_pageHeight);
        ret["shrinkToFit"] = JSONValue(shrinkToFit);
        if (pageRanges != null)
            ret["pageRanges"] = JSONValue(pageRanges);
        return ret;
    }
}
