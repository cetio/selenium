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
    double _pageWidth = 21.59;
    double _pageHeight = 27.94;
    double _marginTop = 1.0;
    double _marginBottom = 1.0;
    double _marginLeft = 1.0;
    double _marginRight = 1.0;

public:
    /// Page orientation, defaulting to portrait.
    Orientation orientation = Orientation.Portrait;
    /// Whether to print background graphics, defaulting to false.
    bool background;
    /// Whether to shrink content to fit the page, defaulting to true.
    bool shrinkToFit = true;
    /// Page ranges to print.
    string[] pageRanges;

    /// Paper width in centimeters, defaulting to 21.59 (US Letter).
    @property double pageWidth() const
        => _pageWidth;

    /**
     * Sets the paper width.
     *
     * Params:
     *  val = The width in centimeters, must be at least 2.54/72 (1 point).
     *
     * Throws:
     *  InvalidArgumentException if val is less than 2.54/72.
     */
    @property double pageWidth(double val)
    {
        if (val < 2.54 / 72)
            throw new InvalidArgumentException("Print page width must be at least 1 point.");
        return _pageWidth = val;
    }

    /// Paper height in centimeters, defaulting to 27.94 (US Letter).
    @property double pageHeight() const
        => _pageHeight;

    /**
     * Sets the paper height.
     *
     * Params:
     *  val = The height in centimeters, must be at least 2.54/72 (1 point).
     *
     * Throws:
     *  InvalidArgumentException if val is less than 2.54/72.
     */
    @property double pageHeight(double val)
    {
        if (val < 2.54 / 72)
            throw new InvalidArgumentException("Print page height must be at least 1 point.");
        return _pageHeight = val;
    }

    /// Top page margin in centimeters, defaulting to 1.0.
    @property double marginTop() const
        => _marginTop;

    /**
     * Sets the top page margin.
     *
     * Params:
     *  val = The margin in centimeters, must not be negative.
     *
     * Throws:
     *  InvalidArgumentException if val is negative.
     */
    @property double marginTop(double val)
    {
        if (val < 0)
            throw new InvalidArgumentException("Print margin must not be negative.");
        return _marginTop = val;
    }

    /// Bottom page margin in centimeters, defaulting to 1.0.
    @property double marginBottom() const
        => _marginBottom;

    /// Sets the bottom page margin. See marginTop for validation.
    @property double marginBottom(double val)
    {
        if (val < 0)
            throw new InvalidArgumentException("Print margin must not be negative.");
        return _marginBottom = val;
    }

    /// Left page margin in centimeters, defaulting to 1.0.
    @property double marginLeft() const
        => _marginLeft;

    /// Sets the left page margin. See marginTop for validation.
    @property double marginLeft(double val)
    {
        if (val < 0)
            throw new InvalidArgumentException("Print margin must not be negative.");
        return _marginLeft = val;
    }

    /// Right page margin in centimeters, defaulting to 1.0.
    @property double marginRight() const
        => _marginRight;

    /// Sets the right page margin. See marginTop for validation.
    @property double marginRight(double val)
    {
        if (val < 0)
            throw new InvalidArgumentException("Print margin must not be negative.");
        return _marginRight = val;
    }

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

        JSONValue page = JSONValue.emptyObject;
        page["width"] = JSONValue(_pageWidth);
        page["height"] = JSONValue(_pageHeight);
        ret["page"] = page;

        JSONValue margin = JSONValue.emptyObject;
        margin["top"] = JSONValue(_marginTop);
        margin["bottom"] = JSONValue(_marginBottom);
        margin["left"] = JSONValue(_marginLeft);
        margin["right"] = JSONValue(_marginRight);
        ret["margin"] = margin;

        ret["shrinkToFit"] = JSONValue(shrinkToFit);
        if (pageRanges != null)
            ret["pageRanges"] = JSONValue(pageRanges);
        return ret;
    }
}
