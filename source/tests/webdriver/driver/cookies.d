/// Offline tests for the cookie model and cookie-name validation.
module tests.webdriver.driver.cookies;

import selenium.driver : Driver;
import selenium.driver.cookies : Cookie, cookies;
import selenium.exception : InvalidArgumentException;

import unit_threaded;

import std.json : JSONValue;

@Name("Cookie.toJSON defaults path and omits unset optional fields")
unittest
{
    Cookie cookie;
    cookie.name = "name";
    cookie.value = "value";

    JSONValue json = cookie.toJSON();
    json["name"].str.should == "name";
    json["value"].str.should == "value";
    json["path"].str.should == "/";
    json["secure"].boolean.should == false;
    json["httpOnly"].boolean.should == false;
    (("domain" in json) is null).should == true;
    (("expiry" in json) is null).should == true;
    (("sameSite" in json) is null).should == true;
}

@Name("Cookie.toJSON serializes every set attribute")
unittest
{
    Cookie cookie;
    cookie.name = "name";
    cookie.value = "value";
    cookie.path = "/child";
    cookie.domain = "example.com";
    cookie.secure = true;
    cookie.httpOnly = true;
    cookie.expiry = 1_800_000_000;
    cookie.sameSite = "Strict";

    JSONValue json = cookie.toJSON();
    json["path"].str.should == "/child";
    json["domain"].str.should == "example.com";
    json["secure"].boolean.should == true;
    json["httpOnly"].boolean.should == true;
    json["expiry"].integer.should == 1_800_000_000;
    json["sameSite"].str.should == "Strict";
}

@Name("Cookie.fromJSON reads every attribute")
unittest
{
    Cookie cookie = Cookie.fromJSON(JSONValue([
        "name": JSONValue("name"),
        "value": JSONValue("value"),
        "path": JSONValue("/child"),
        "domain": JSONValue("example.com"),
        "secure": JSONValue(true),
        "httpOnly": JSONValue(true),
        "expiry": JSONValue(1_800_000_000),
        "sameSite": JSONValue("Lax"),
    ]));

    cookie.name.should == "name";
    cookie.value.should == "value";
    cookie.path.should == "/child";
    cookie.domain.should == "example.com";
    cookie.secure.should == true;
    cookie.httpOnly.should == true;
    cookie.expiry.should == 1_800_000_000;
    cookie.sameSite.should == "Lax";
}

@Name("Cookie.fromJSON defaults absent optional attributes")
unittest
{
    Cookie cookie = Cookie.fromJSON(JSONValue([
        "name": JSONValue("name"),
        "value": JSONValue("value"),
    ]));

    cookie.name.should == "name";
    cookie.value.should == "value";
    (cookie.path is null).should == true;
    (cookie.domain is null).should == true;
    cookie.secure.should == false;
    cookie.httpOnly.should == false;
    cookie.expiry.should == 0;
    (cookie.sameSite is null).should == true;
}

@Name("CookieStore find rejects an empty cookie name")
unittest
{
    Driver driver = new Driver();
    driver.cookies.find("").shouldThrow!InvalidArgumentException;
    driver.cookies.find(null).shouldThrow!InvalidArgumentException;
}

@Name("CookieStore remove rejects an empty cookie name")
unittest
{
    Driver driver = new Driver();
    driver.cookies.remove("").shouldThrow!InvalidArgumentException;
    driver.cookies.remove(null).shouldThrow!InvalidArgumentException;
}
