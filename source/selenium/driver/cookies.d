module selenium.driver.cookies;

import selenium.driver : Driver;

import std.json : JSONValue;
import std.net.curl : HTTP;

struct Cookie
{
    string name;
    string value;
    string path;
    string domain;
    bool secure;
    bool httpOnly;
    uint expiry;
    string sameSite;

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
}

struct CookieStore
{
private:
    Driver driver;

package:
    this(Driver driver)
    {
        driver = driver;
    }

public:
    Cookie[] all()
        => driver.bridge.request!(Cookie[])(driver.id, HTTP.Method.get, "/cookie");

    Cookie find(string name)
        => driver.bridge.request!Cookie(driver.id, HTTP.Method.get, "/cookie/"~name);

    void add(Cookie cookie)
    {
        // TODO: Must set cookie domain to current URL??
        driver.bridge.request(
            driver.id,
            HTTP.Method.post,
            "/cookie",
            ["cookie": cookie.toJSON()]
        );
    }

    void remove(string name)
        => driver.bridge.request!void(driver.id, HTTP.Method.del, "/cookie/"~name);

    void clear()
        => driver.bridge.request!void(driver.id, HTTP.Method.del, "/cookie");
}

CookieStore cookies(Driver driver)
    => CookieStore(driver);
