/// Offline tests for the W3C `/print` request body model.
module tests.webdriver.driver.print;

import selenium.driver.print : Orientation, PrintOptions;
import selenium.exception : InvalidArgumentException;

import unit_threaded;

import std.json : JSONValue, JSONType;

@Name("PrintOptions defaults to portrait US Letter at 100% scale")
unittest
{
    PrintOptions options;
    options.orientation.should == Orientation.Portrait;
    options.scale.should == 1.0;
    options.background.should == false;
    options.pageWidth.should == 8.5;
    options.pageHeight.should == 11.0;
    options.shrinkToFit.should == true;
    options.pageRanges.length.should == 0;
}

@Name("PrintOptions toJSON omits empty pageRanges")
unittest
{
    PrintOptions options;
    options.background = true;
    JSONValue json = options.toJSON();

    json["orientation"].str.should == "portrait";
    json["scale"].floating.should == 1.0;
    json["background"].boolean.should == true;
    json["pageWidth"].floating.should == 8.5;
    json["pageHeight"].floating.should == 11.0;
    json["shrinkToFit"].boolean.should == true;
    (("pageRanges" in json) is null).should == true;
}

@Name("PrintOptions toJSON includes pageRanges when set")
unittest
{
    PrintOptions options;
    options.pageRanges = ["1-3", "5"];
    JSONValue json = options.toJSON();
    json["pageRanges"].type.should == JSONType.array;
    json["pageRanges"].array.length.should == 2;
    json["pageRanges"].array[0].str.should == "1-3";
    json["pageRanges"].array[1].str.should == "5";
}

@Name("PrintOptions toJSON serializes landscape orientation")
unittest
{
    PrintOptions options;
    options.orientation = Orientation.Landscape;
    options.toJSON()["orientation"].str.should == "landscape";
}

@Name("PrintOptions scale setter rejects values below 0.1")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.scale = 0.05;
}

@Name("PrintOptions scale setter rejects values above 2.0")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.scale = 2.5;
}

@Name("PrintOptions pageWidth setter rejects non-positive values")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.pageWidth = 0;
}

@Name("PrintOptions pageHeight setter rejects non-positive values")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.pageHeight = -1;
}

@Name("PrintOptions scale setter accepts boundary values")
unittest
{
    PrintOptions options;
    options.scale = 0.1;
    options.scale.should == 0.1;
    options.scale = 2.0;
    options.scale.should == 2.0;
}

@Name("PrintOptions pageWidth setter accepts positive values")
unittest
{
    PrintOptions options;
    options.pageWidth = 5.5;
    options.pageWidth.should == 5.5;
}

@Name("PrintOptions pageHeight setter accepts positive values")
unittest
{
    PrintOptions options;
    options.pageHeight = 17.0;
    options.pageHeight.should == 17.0;
}
