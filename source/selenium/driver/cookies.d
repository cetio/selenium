/// Cookie model and the per-session cookie store.
module selenium.driver.cookies;

import selenium.driver : Driver;

import std.json : JSONValue;

/// A single WebDriver cookie.
struct Cookie
{
    /// The cookie name.
    string name;
    /// The cookie value.
    string value;
    /// The path the cookie is valid for, defaulting to "/" when serialized.
    string path;
    /// The domain the cookie is valid for, omitted from output when empty.
    string domain;
    /// Whether the cookie is restricted to secure transports.
    bool secure;
    /// Whether the cookie is inaccessible to client-side scripts.
    bool httpOnly;
    /// Unix expiry time in seconds, omitted from output when zero.
    uint expiry;
    /// SameSite policy, omitted from output when empty.
    string sameSite;

    /// Serializes the cookie, omitting optional fields that are unset.
    JSONValue toJSON() const
    {
        JSONValue ret = JSONValue.emptyObject;
        ret["name"] = JSONValue(name);
        ret["value"] = JSONValue(value);
        ret["httpOnly"] = JSONValue(httpOnly);
        ret["secure"] = JSONValue(secure);
        ret["path"] = path == null ? "/" : path;
        
        // Should not be provided if not set.
        if (domain != null)
            ret["domain"] = JSONValue(domain);
        if (expiry > 0)
            ret["expiry"] = JSONValue(expiry);
        if (sameSite != null)
            ret["sameSite"] = JSONValue(sameSite);
        return ret;
    }

    static Cookie fromJSON(JSONValue json)
    {
        Cookie ret;
        ret.name = json["name"].get!string;
        ret.value = json["value"].get!string;
        if ("path" in json)
            ret.path = json["path"].get!string;

        if ("domain" in json)
            ret.domain = json["domain"].get!string;

        if ("secure" in json)
            ret.secure = json["secure"].get!bool;

        if ("httpOnly" in json)
            ret.httpOnly = json["httpOnly"].get!bool;

        if ("expiry" in json)
            ret.expiry = json["expiry"].get!uint;

        if ("sameSite" in json)
            ret.sameSite = json["sameSite"].get!string;
        return ret;
    }
}

/// Cookie operations scoped to a single driver session.
///
/// This store is intentionally decoupled from `Driver` and reached through the
/// `cookies` UFCS helper rather than living on the driver itself.
struct CookieStore
{
private:
    /// The session whose cookies are operated on.
    Driver driver;

package:
    /// Binds the store to a driver session.
    this(Driver driver)
    {
        driver = driver;
    }

public:
    /// Every cookie visible to the current document.
    Cookie[] all()
    {
        JSONValue value = driver.bridge.unwrapAndParse!JSONValue(driver.bridge.get(driver.id, "/cookie"));
        Cookie[] ret;
        foreach (json; value.array)
            ret ~= Cookie.fromJSON(json);
        return ret;
    }

    /**
     * Reads a single cookie by name.
     *
     * Params:
     *  name = The cookie name.
     *
     * Returns:
     *  The matching cookie.
     */
    Cookie find(string name)
    {
        JSONValue json = driver.bridge.unwrapAndParse!JSONValue(driver.bridge.get(driver.id, "/cookie/"~name));
        return Cookie.fromJSON(json);
    }

    /**
     * Adds or updates a cookie on the current document.
     *
     * Params:
     *  cookie = The cookie to set.
     */
    void add(Cookie cookie)
    {
        // TODO: Must set cookie domain to current URL??
        driver.bridge.post(
            driver.id,
            "/cookie",
            JSONValue(["cookie": cookie.toJSON()])
        );
    }

    /**
     * Deletes a single cookie by name.
     *
     * Params:
     *  name = The cookie name.
     */
    void remove(string name)
        => driver.bridge.del!void(driver.id, "/cookie/"~name);

    /// Deletes every cookie for the current document.
    void clear()
        => driver.bridge.del!void(driver.id, "/cookie");
}

/// Opens the cookie store for a session, used as `driver.cookies`.
CookieStore cookies(Driver driver)
    => CookieStore(driver);
