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
    options.pageWidth.should == 21.59;
    options.pageHeight.should == 27.94;
    options.shrinkToFit.should == true;
    options.pageRanges.length.should == 0;
}

@Name("PrintOptions defaults margins to 1 cm each")
unittest
{
    PrintOptions options;
    options.marginTop.should == 1.0;
    options.marginBottom.should == 1.0;
    options.marginLeft.should == 1.0;
    options.marginRight.should == 1.0;
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
    json["page"]["width"].floating.should == 21.59;
    json["page"]["height"].floating.should == 27.94;
    json["margin"]["top"].floating.should == 1.0;
    json["margin"]["bottom"].floating.should == 1.0;
    json["margin"]["left"].floating.should == 1.0;
    json["margin"]["right"].floating.should == 1.0;
    json["shrinkToFit"].boolean.should == true;
    (("pageRanges" in json) is null).should == true;
}

@Name("PrintOptions toJSON omits flat pageWidth/pageHeight keys")
unittest
{
    PrintOptions options;
    JSONValue json = options.toJSON();
    (("pageWidth" in json) is null).should == true;
    (("pageHeight" in json) is null).should == true;
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

@Name("PrintOptions toJSON nests custom page and margin values")
unittest
{
    PrintOptions options;
    options.pageWidth = 29.7;
    options.pageHeight = 42.0;
    options.marginTop = 2.0;
    options.marginBottom = 1.5;
    options.marginLeft = 1.0;
    options.marginRight = 0.5;
    JSONValue json = options.toJSON();
    json["page"]["width"].floating.should == 29.7;
    json["page"]["height"].floating.should == 42.0;
    json["margin"]["top"].floating.should == 2.0;
    json["margin"]["bottom"].floating.should == 1.5;
    json["margin"]["left"].floating.should == 1.0;
    json["margin"]["right"].floating.should == 0.5;
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

@Name("PrintOptions pageWidth setter rejects values below 1 point")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.pageWidth = 0;
}

@Name("PrintOptions pageHeight setter rejects values below 1 point")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.pageHeight = -1;
}

@Name("PrintOptions marginTop setter rejects negative values")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.marginTop = -0.1;
}

@Name("PrintOptions marginBottom setter rejects negative values")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.marginBottom = -1.0;
}

@Name("PrintOptions marginLeft setter rejects negative values")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.marginLeft = -0.01;
}

@Name("PrintOptions marginRight setter rejects negative values")
@ShouldFailWith!InvalidArgumentException
unittest
{
    PrintOptions options;
    options.marginRight = -2.0;
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

@Name("PrintOptions pageWidth setter accepts values at least 1 point")
unittest
{
    PrintOptions options;
    options.pageWidth = 21.0;
    options.pageWidth.should == 21.0;
}

@Name("PrintOptions pageHeight setter accepts values at least 1 point")
unittest
{
    PrintOptions options;
    options.pageHeight = 29.7;
    options.pageHeight.should == 29.7;
}

@Name("PrintOptions margin setters accept non-negative values")
unittest
{
    PrintOptions options;
    options.marginTop = 0.0;
    options.marginTop.should == 0.0;
    options.marginBottom = 2.5;
    options.marginBottom.should == 2.5;
    options.marginLeft = 1.0;
    options.marginLeft.should == 1.0;
    options.marginRight = 3.0;
    options.marginRight.should == 3.0;
}
