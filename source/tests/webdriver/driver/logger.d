module tests.webdriver.driver.logger;

import selenium.browser : Browser;
import selenium.browser.firefox : Firefox;
import selenium.browser.safari : Safari;
import selenium.driver.logger :
    LogLevel,
    Logger,
    fromGeckoDriverLevel,
    toGeckoDriverLevel,
    toWebDriverLevel;

import unit_threaded;

import std.json : JSONValue;

// TODO: Technically this doesn't really belong here. 
//       Browser specific unit tests should be in their own module.
//       Not a big deal for now...

@Name("Logger toDriverArgs builds Chromium flags")
unittest
{
    Logger logger = new Logger();
    logger.path = "/tmp/driver.log";
    logger.driverLevel = LogLevel.warning;
    logger.append = true;
    logger.readableTimestamp = true;
    logger.silent = true;

    logger.toDriverArgs().should == [
        "--log-path=/tmp/driver.log",
        "--log-level="~toWebDriverLevel(LogLevel.warning),
        "--append-log",
        "--readable-timestamp",
        "--silent"
    ];
}

@Name("Logger toDriverArgs defaults to Chromium behavior")
unittest
{
    Logger logger = new Logger();
    logger.driverLevel = LogLevel.info;
    logger.toDriverArgs().should == logger.toDriverArgs(null);
    logger.toDriverArgs(null).should == ["--log-level="~toWebDriverLevel(LogLevel.info)];
}

@Name("Logger toDriverArgs maps driverLevel for Firefox")
unittest
{
    Logger logger = new Logger();
    logger.driverLevel = LogLevel.error;
    logger.toDriverArgs(new Firefox()).should == ["--log", "error"];
}

@Name("Logger toDriverArgs omits Chromium-only flags for Firefox")
unittest
{
    Logger logger = new Logger();
    logger.path = "/tmp/driver.log";
    logger.driverLevel = LogLevel.trace;
    logger.append = true;
    logger.readableTimestamp = true;
    logger.silent = true;

    logger.toDriverArgs(new Firefox()).should == ["--log", "debug"];
}

@Name("Logger toDriverArgs returns empty for Firefox at off level")
unittest
{
    Logger logger = new Logger();
    logger.path = "/tmp/driver.log";
    logger.toDriverArgs(new Firefox()).should == string[].init;
}

@Name("Logger toDriverArgs returns empty for Safari")
unittest
{
    Logger logger = new Logger();
    logger.path = "/tmp/driver.log";
    logger.driverLevel = LogLevel.all;
    logger.toDriverArgs(new Safari()).should == string[].init;
}

@Name("Logger toDriverArgs returns empty for a generic browser")
unittest
{
    Logger logger = new Logger();
    logger.driverLevel = LogLevel.info;
    logger.toDriverArgs(new Browser()).should == string[].init;
}

@Name("toGeckoDriverLevel maps std.logger levels")
unittest
{
    toGeckoDriverLevel(LogLevel.error).should == "error";
    toGeckoDriverLevel(LogLevel.warning).should == "warn";
    toGeckoDriverLevel(LogLevel.info).should == "info";
    toGeckoDriverLevel(LogLevel.trace).should == "debug";
    toGeckoDriverLevel(LogLevel.all).should == "trace";
    toGeckoDriverLevel(LogLevel.off).should == "fatal";
}

@Name("fromGeckoDriverLevel maps geckodriver strings")
unittest
{
    fromGeckoDriverLevel("fatal").should == LogLevel.error;
    fromGeckoDriverLevel("error").should == LogLevel.error;
    fromGeckoDriverLevel("warn").should == LogLevel.warning;
    fromGeckoDriverLevel("info").should == LogLevel.info;
    fromGeckoDriverLevel("config").should == LogLevel.info;
    fromGeckoDriverLevel("debug").should == LogLevel.trace;
    fromGeckoDriverLevel("trace").should == LogLevel.all;
    fromGeckoDriverLevel("nonsense").should == LogLevel.off;
}

@Name("Firefox toJSON serializes moz log level")
unittest
{
    Firefox firefox = new Firefox();
    JSONValue json = firefox.toJSON();
    (("moz:firefoxOptions" in json) is null).should == true;

    firefox.logLevel = LogLevel.trace;
    json = firefox.toJSON();
    json["moz:firefoxOptions"]["log"]["level"].str.should == "debug";
}

@Name("Firefox parses and roundtrips moz log level")
unittest
{
    Firefox firefox = new Firefox();
    firefox.logLevel = LogLevel.all;
    Firefox roundTrip = cast(Firefox)Browser.fromJSONValue(firefox.toJSON());
    roundTrip.logLevel.should == LogLevel.all;
}
