---
layout: post
title: PHP Guide to Making HTTP API Requests
date: 2018-07-28 08:51
comments: true
categories: PHP
published: true
---

For a web-focused language, PHP doesn't make it easy or obvious how to call out
over to other servers to make API requests. I compiled all the information I found
into this post, a resource I wish I had yesterday when writing an API client.

Also, I needed a dependency-free approach that didn't use special PHP libraries
or extensions (like [cURL](http://php.net/manual/fa/book.curl.php))
and still supports older versions of PHP that exist in the wild.

## GET Requests (Read by URL)

PHP hid it's feature to download a page from the web in the
[file_get_contents()]() function, which makes discovery hard.

    $url = "https://www.google.com/"
    $page = file_get_contents($url);

This performs a "GET" request for the URL and returns the contents.

What about GET parameters? Another useful function can build the query string:
[http_build_query()](http://php.net/manual/en/function.http-build-query.php).

The "query string" is the part of the URL after the domain and path, separated
by the "?" character. This does not have to be a structured format, but most
web apps use it to hold a set of "name=value" pairs. These are mostly used to
search and filter the data being returned.

    $url = "https://www.google.com/"
    $q   = array("q"=>"PHP HTTP request");
    $page = file_get_contents($url . '?' . http_build_query($q);
            // https://www.google.com/?q=PHP+HTTP+request

## POST and Advanced Requests

If you need other HTTP features, you are going to need another trick: setting
up a PHP context, which holds meta-information for I/O operations.
The [stream_context_create()](http://php.net/manual/en/function.stream-context-create.php)
function builds the context that you pass to `file_get_contents()`.
The full [HTTP context options](http://php.net/manual/en/context.http.php) page
documents what you can pass into `stream_context_create()`.
Pass an associative array of 'http' => another array of options.

Here, let's send the same request as a POST. POST data is sent as a content body,
after the HTTP headers. `http_build_query()` returns data encoded in the same way
web browsers send form data. We just set the "Content-Type" header on the request
to tell the web server which format we are sending.

    $url = "https://www.google.com/"
    $q   = array("q"=>"PHP HTTP request");
    $opt = array('http'=>array(
           'method' => 'POST',
           'headers => "Content-Type: application/x-www-form-urlencoded",
           'content => http_build_query($q)
           ));
    $context = stream_context_create($opt);
    $response = file_get_contents($url, false, $context);

This creates a HTTP request that looks like this:

    POST / HTTP/1.1
    Host: www.google.com
    Content-Type: application/x-www-form-urlencoded

    q=PHP+HTTP+request

## Additional Headers

So far, so good! Now to turn our attention to making an API request to
some service on the internet. We are going to need to craft additional headers.
Let's create an array of additional headers:

    $headers   = array();
    $headers[] = "Content-Type: application/x-www-form-urlencoded";

### Accept

First, we want the data returned in [JSON](https://en.wikipedia.org/wiki/JSON)
format, so we need an [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept<Paste>)
header to tell the remote web server what we want.

    $headers[] = "Accept: application/json";

### Authorization

Also, we have an Api Key given to us by that service for identification.
There are different ways to pass your key to the service, though the most
useful is using [HTTP Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication).

PHP decodes incoming Basic Auth headers into `$_SERVER['PHP_AUTH_USER']` and `$_SERVER['PHP_AUTH_PW']`
but does not provide a feature to send our own, but it's easy enough to roll.
The string "username:password" (no quotes) is Base64 encoded to prevent characters
from disturbing the HTTP header protocol. For an API key, we format with an empty password,
so really just appending the colon after the key: "apikey:"

    $headers[] = "Authorization: Basic ".base64_encode($apikey.":");

Which creates the header that looks something like this:

    Authorization: Basic dXNlcjpwYXNzd29yZA==

I could not find documentation that PHP would create the Authorization header
from a URL with the user/password prepended, so I doubt this would work,
and if so, may very version to version:

    https://user:password@example.com/

If you have a token, usually from [Oauth2](https://oauth.net/2/)
or a [JSON Web Token](https://jwt.io/) or JWT passed after login,
The "Bearer" format of the header is used:

    Authorization: Bearer 1bc24312976e67402a1a8aac4b3257e48d6d1a53f94de548afe945dfeccbb94e

and can be added to your headers as:

    $headers[] = "Authorization: Bearer $token";

### Cookies

Usually, we don't need cookies for API requests, but some services use it to
transfer your credentials, an API key or
[JWT](https://en.wikipedia.org/wiki/JSON_Web_Token) token.
We can add each cookie header as follows with whatever name and value you have.

    $headers[] = "Cookie: apikey=$apikey";

Encoding of cookie strings is not well defined.
Use the values returned previously from the remote server if available as they
are in the format (url-encoded, Base64, etc) and character set expected to be received.
Simple ASCII strings like the apikey example should work as expected.


### User-Agent

We should identify what service is making the request -- our program and version.
We don't need a special header for this! We can set this up the `stream_context_create()`
arguments, right alongside the "method" parameter:

    'user_agent' => "My App/v1.0"

Of course, we can always create the header ourselves:

    $headers[] = "User-Agent: My App/v1.0";

The [user agent](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent)
string is of the format

    User-Agent: <product> / <product-version> <comment>

### Building headers

Now we have an array of additional HTTP Request headers in `$headers`.
The HTTP protocol requires the "\r\n" line end sequence between header lines.
So we set up our context options like this:

    $opt = array('http'=>array(
           'method' => 'POST',
           'user_agent' => "My App/v1.0",
           'headers' => implode("\r\n", $headers),
           'content' => http_build_query($q)
           ));

## Sending Files

PHP Doesn't support sending files over HTTP either. But this isn't all that hard;
we need to understand [MIME](https://en.wikipedia.org/wiki/MIME)
encoding. If you every looked at the raw source of an email message, you've likely
seen MIME coding in action.  We need to have a boundary string to separate each
part--in our case, each file and POST parameter. When we switch to sending content
in MIME "multipart" format, even the POST parameters are formatted this way as well.

Here is the structure of a MIME body, with headers:

    MIME-Version: 1.0
    Content-Type: multipart/form-data; boundary=-------XXXXXXX

    -------XXXXXXX
    Content-Dispostion: form-data; name="q"

    PHP HTTP request
    -------XXXXXXX
    Content-Dispostion: form-data; name="avatar"; filename="avatar.png"
    Content-Type: image/png

    [contents of file]
    -------XXXXXXX--

Notice the final line boundary is followed by two hyphens to indicate the end of the parts.

NOTE: It seems HTTP is cool with transferring binary files like this without Base64 encoding
like we would need in an email message.

In code, we generate a unique boundary string (`-------XXXXXXX` doesn't cut it).
Then we build each line of the content, and finally join them together.

    $boundary = '--------------------------'.microtime(true);
    $content = array();

    // $files = array( array('path'=>"/path/file", 'filename'=>'avatar.png", 'type'=>"image/png"), ...);
    foreach ($files as $field=>$f) {
      $content[] ="--$boundary";
      $content[] = "Content-Disposition: form-data; name=\"$field\"; filename=\"".basename($filename)."\"";
      $content[] = "Content-Type: {$f['type']}";
      $content[] = "";
      $content[] = file_get_contents($f['path']);
      $content[] = "";
    }
    foreach ($q as $field=>$v) {
      $content[] ="--$boundary";
      $content[] = "Content-Disposition: form-data; name=\"$field\"";
      $content[] = "";
      $content[] = $v;
      $content[] = "";
    }
    $content[] ="--$boundary--";

    $headers[] = "Content-Type: multipart/form-data; boundary=$boundary";
    $body = implode("\r\n", $content));

In this case, we set the Content-Type differently than previously. Don't send both!

Then we set the HTTP context like this:

    $opt = array('http'=>array(
           'method' => 'POST',
           'user_agent' => "My App/v1.0",
           'headers' => implode("\r\n", $headers),
           'content' => $body
           ));

Note that a very large file payload could cause your memory usage to spike. There is no
way to chunk out the data using this method.

## Responses and Errors

`file_get_contents()` returns the body of the response after processing.

On an error, it returns FALSE. When testing for FALSE in PHP,
remember to use the `===` or "three-qual" operator.
Unfortunately, is also swallows the page, so if a detailed error
message is on the body of the page--which is a proper response--there
is no way to see it.

To quiet the errors, call it with the special "@" PHP prefix.
FALSE seems to be returned when there was no connection or response from the web server.
For connection errors, you need to call
[error_get_last()](http://php.net/manual/en/function.error-get-last.php)
after the operation.

    $url     = "https://www.google.com/"
    $q       = array("q"=>"PHP HTTP request");
    $opt     = array(...);
    $context = stream_context_create($opt);
    $result  = @file_get_contents($url, false, $context);
    if ($result === FALSE) {
      $last_err = error_get_last();
      echo $last_err['message'];
    }

The response headers are in a special local variable, `$http_response_header`.
It is an array of the headers received, not parsed. They can be useful in debugging.

    [0] => HTTP/1.1 200 OK
    [1] => Date: Sat, 28 Jul 2018 14:34:49 GMT
    [2] => Server: Apache/2.4.28 (Unix) LibreSSL/2.2.7
    [3] => Pragma: cache
    [4] => Cache-Control: cache
    [5] => Last-Modified: Sat, 28 Jul 2018 14:34:49 GMT
    [6] => Expires: Sat, 28 Jul 2018 14:34:49 GMT
    [7] => Connection: close
    [8] => Content-Type: application/json; charset=UTF-8

### Additional context

The `stream_context_create()` takes a couple more useful parameters: 'timeout'
(float) and 'ignore_errors' which still returns the content when an error is
detected. Sometimes a useful error message is in that content.

    $opt = array('http'=>array(
           'method' => 'GET',
           'timeout' => 10.0,
           'ignore_errors' => true,
           ));

### Receiving Cookies

When a web server returns a cookie to be resent on subsequent request it will send a
[Set-Cookie](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie)
response header for each cookie.

    Set-Cookie: sessionid=38afes7a8; HttpOnly; Path=/

Since API's don't use cookie-based sessions, I won't cover it here, but the Set-Cookie
documentation shows the various directives to process one.

### Receiving Files

Receiving files from a remote API request was out of the scope of this post, but is discussed here for completeness.

The [Content-Disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition)
header is normally set to "inline" for standard pages and responses.

    Content-Disposition: inline

When a file is returned, it is set to "attachment." For web browsers, this usually triggers a "Save as"
dialog unless configured to store it in your default download folder.
The API client would need to identify the attachment and save to to a pre-determined location.

    HTTP/1.1 200 OK
    Content-Type: text/csv; charset=utf-8
    Content-Disposition: attachment; filename="data.csv"
    Content-Length: 123

    <File Contents>

Additionally, complex results can send "multipart" responses with multiple attachments.
For this case, it is best to use a MIME parsing library.

    HTTP/1.1 200 OK
    Content-Length: 10215
    Content-Type: multipart/mixed; boundary="boundary";

    --boundary
    Content-Type: text/csv; charset=utf-8
    Content-Disposition: attachment; filename="data1.csv"

    <File Contents>
    --boundary
    Content-Type: text/csv; charset=utf-8
    Content-Disposition: attachment; filename="data2.csv"

    <File Contents>
    --boundary--

## HEAD Request

The [get_headers($url,$format,$context)](http://php.net/manual/en/function.get-headers.php)
function makes a HEAD method request with returns only headers without a body.
The $format argument should be zero to return a list of headers, or non-zero to
return an associative array of header names to values.

## Callbacks

PHP offers a request callback, when fires at each event in processing your request.
Generally, you won't need it, but it is great for tracking progress of receiving
large files.

Call [stream_context_set_params()](http://php.net/manual/en/function.stream-context-set-params.php)
passing a "callable" function with the signature matching
[stream_notification_callback()](http://php.net/manual/en/function.stream-notification-callback.php).

    $context = stream_context_create($opt);
    stream_context_set_params($context, array("notification" => "my_notification_callback"));
    $response = @file_get_contents($url, false, $context);

    function my_notification_callback($notification_code, $severity, $message,
                                           $message_code, $bytes_transferred, $bytes_max) {
      global $_http_state;
      $_http_state = array($notification_code, $severity, $message,
        $message_code, $bytes_transferred, $bytes_max);
    }

Better explanation and examples are found on the
[stream_notification_callback()](http://php.net/manual/en/function.stream-notification-callback.php) page.

## A Simple HTTP Client

We can put all we know together to write a simple HTTP client:

### Source here: [http_request()](https://gist.github.com/afair/a7c7adc52b7b49bf362935e665a87633)

You should be able to get the parts you need from this example.
I have not fully tested this code, so you may find edge cases that need to be fixed. Good luck!

<script src="https://gist.github.com/afair/a7c7adc52b7b49bf362935e665a87633.js"></script>

### Attribution

I compiled this from a dozen or so stack overflow answers from people who I wish I
could credit, but neglected to save their names.  Apologies and thanks to those PHP masters wherever you are!

Hmm, I just found a PHP extension [http_request](http://php.net/manual/fa/function.http-request.php)
of the same name I use for this function. Sorry about any confusion.
