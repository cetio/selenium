/// Element locators pairing a W3C location strategy with a selector.
module selenium.locator;

import selenium.exception : InvalidSelectorException;

import std.json : JSONValue;

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
