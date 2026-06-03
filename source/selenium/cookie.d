module selenium.cookie;

struct Cookie
{
    string name;
    string value;
    string path;
    string domain;
    bool httpOnly;
    bool secure;
    long expiry;
}
