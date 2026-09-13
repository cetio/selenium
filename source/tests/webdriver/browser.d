/// Offline browser capability serialization tests.
module tests.webdriver.browser;

import selenium.browser.firefox : Firefox;

import unit_threaded;

import std.file : tempDir;
import std.json : JSONValue;

@Name("Firefox filesystem profile serializes as separate args")
unittest
{
    Firefox firefox = new Firefox();
    firefox.profile = tempDir();
    JSONValue json = firefox.toJSON();
    JSONValue[] args = json["moz:firefoxOptions"]["args"].array;
    args.length.should == 2;
    args[0].str.should == "-profile";
    args[1].str.should == firefox.profile;
}
