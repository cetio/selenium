/// HTTP utilities and a minimal loopback HTTP server.
module tests.common.http;

import std.conv : to;
import std.socket;
import std.string : indexOf;

import core.thread : Thread;

/// A URL on a loopback HTTP origin, starting a minimal test server on first use.
///
/// Cookies and other behavior tied to a real document origin cannot be exercised from a
/// `data:` URL. The server answers every request with a small HTML document.
string localUri(string path = "/")
{
    if (_origin is null)
        _origin = startServer();
    return _origin~path;
}

private:

__gshared string _origin;
__gshared Socket _socket;
__gshared Thread _thread;

string startServer()
{
    Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM);
    socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
    socket.bind(new InternetAddress("127.0.0.1", 0));
    socket.listen(16);

    ushort port = (cast(InternetAddress)socket.localAddress).port;
    _socket = socket;
    _thread = new Thread({
        while (true)
        {
            Socket client;
            try
                client = socket.accept();
            catch (Exception)
                break;

            try
                respond(client);
            catch (Exception) { }
            finally
                client.close();
        }
    });
    _thread.isDaemon = true;
    _thread.start();

    return "http://127.0.0.1:"~port.to!string;
}

void respond(Socket client)
{
    char[1024] buffer;
    string request;
    while (request.indexOf("\r\n\r\n") < 0)
    {
        ptrdiff_t count = client.receive(buffer);
        if (count <= 0)
            return;
        request ~= buffer[0 .. count];
    }

    string body = "<html><body><p>test page</p></body></html>";
    client.send(
        "HTTP/1.1 200 OK\r\n"
        ~"Content-Type: text/html; charset=utf-8\r\n"
        ~"Content-Length: "~body.length.to!string~"\r\n"
        ~"Connection: close\r\n\r\n"
        ~body
    );
}
