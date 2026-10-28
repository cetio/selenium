/// Test page helpers.
module tests.common.page;

import std.uri : encodeComponent;

/// Encodes an HTML document as a `data:` URL.
string dataUri(string html)
    => "data:text/html;charset=utf-8,"~encodeComponent(html);
