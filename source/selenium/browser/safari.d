module selenium.browser.safari;

import selenium.browser : Browser;

import std.json : JSONValue, JSONType;

class Safari : Browser
{
    // https://developer.apple.com/documentation/webkit/about-webdriver-for-safari
    // https://webkit.org/blog/6900/webdriver-support-in-safari-10/
    /// Preload the Web Inspector and JavaScript debugger in the background.
    bool automaticInspection;
    /// Enable the Automation profiling.
    bool automaticProfiling;
    /// Use Safari Technology Preview instead of the release version of Safari.
    bool technologyPreview;

    override string name() const
        => technologyPreview ? "Safari Technology Preview" : "safari";

    override JSONValue toJSON() const
    {
        JSONValue ret = super.toJSON();
        if (automaticInspection)
            ret["safari:automaticInspection"] = JSONValue(true);
        if (automaticProfiling)
            ret["safari:automaticProfiling"] = JSONValue(true);
        return ret;
    }

protected:
    override void parseFrom(JSONValue value)
    {
        super.parseFrom(value);

        if ("browserName" in value && value["browserName"].type == JSONType.string)
            technologyPreview = value["browserName"].str == "Safari Technology Preview";

        if ("safari:automaticInspection" in value)
        {
            if (value["safari:automaticInspection"].type == JSONType.true_)
                automaticInspection = true;
            else if (value["safari:automaticInspection"].type == JSONType.false_)
                automaticInspection = false;
        }

        if ("safari:automaticProfiling" in value)
        {
            if (value["safari:automaticProfiling"].type == JSONType.true_)
                automaticProfiling = true;
            else if (value["safari:automaticProfiling"].type == JSONType.false_)
                automaticProfiling = false;
        }
    }
}
