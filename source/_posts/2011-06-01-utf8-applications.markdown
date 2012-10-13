---
layout: post
title: UTF-8 Applications
---
# UTF-8 Applications: from   to  

Last year, I upgraded an application to use Unicode with [UTF-8](http://en.wikipedia.org/wiki/UTF-8) [character encoding](http://en.wikipedia.org/wiki/Character_encoding) instead of ASCII encodings. I quickly ran into unexpected problems. As with anything, you have to know how it works to avoid its pitfalls. ASCII is essentially a binary encoding in that a string was a sequence of bytes, and there was no "invalid" value. UTF-8 is a character-based encoding and not every binary combination represents a valid Unicode character or code point. My language runtimes and databases complained about the data it was fed.

##TL;DR

Don't trust your input character encoding. Modern web browsers send data to your application in UTF-8 encoding in response to UTF-8 web pages. Not all HTTP clients, email, files, and network transfers are guaranteed to be in your expected character encoding. Know your tools to handle non-UTF-8 data to determine the incoming encoding and translate them to UTF-8 for processing.

## Working with UTF-8

UTF-8 is a variable-length multi-byte encoding for the Unicode character set. It is backward-compatible with the 7-bit
[ASCII](http://en.wikipedia.org/wiki/ASCII) character sets used in the English language. If you are still new to UTF-8, no better tutorial is available than 
[The Absolute Minimum Every Software Developer Absolutely, Positively Must Know About Unicode and Character Sets (No Excuses!)](http://www.joelonsoftware.com/articles/Unicode.html) by Joel Spolsky.

[Unicode](http://en.wikipedia.org/wiki/Unicode) refers to the character set--or characters represented by the writing system, and UTF-8 refers to the encoding of those characters as bit in memory or data storage. There are other Unicode Encodings (UTF-16, UTF-32), but UTF-8 is the preferred one. A Unicode code point, represented "u+0000", points to a character in the Unicode specification. UTF-8 is the representation of that number in a sequence of bytes and does not directly map that code point number as a binary number. It is a series of binary fields and flags, with the value spread out in certain bits on the required bytes. See the [diagram](http://en.wikipedia.org/wiki/UTF-8#Design) for the layout.

Most of what we here use these days is the 8-bit, Latin-1 character set for Western European languages, officially known as [ISO-8859-1](http://en.wikipedia.org/wiki/Iso-8859). If your application interacts with people and computer systems from the non-Latin-1 ecosystem, you will run into problems if you are not using UTF-8.

### Terminology

Writing System
:    a symbolic system used to represent elements or statements expressible in language.

Orthography
:    A standardized writing system for a language

Glyph
:    A mark for a written language with meaning, including base letter shapes, diacritics, etc.

Diacritic
:    an ancillary mark added to a letter, such as an accent, cedilla, umlaut, etc.

Grapheme
:    A fundamental unit of writing, including Asian characters, digits, punctuations, words and syllable characters, and letters with optional diacritics, and ligatures. Consider this a full character.

Ligature
:    a symbol or two or more graphemes are joined as a single glyph.

Digraph
:    a pair of characters used to write one phoneme (distinct sound) (ch, sh, etc.)

Transliteration
:    the practice of converting a text from one script into another. (Russian/Cyrillic or Greek to English)

Character
:    a unit of information that roughly corresponds to a grapheme, grapheme-like unit, or symbol, such as in an alphabet or syllabary in the written form of a natural language.

Character Encoding
:    numeric representation system for a character set

Code Point
:    the numerical representation for the graphical representation of the character.

Universal Character Set
:    standard set of characters, with a unique name and integer for each, upon which many character encodings are based. 

Unicode
:    the character encoding of the universal character set with 1,112,064 code points.

UTF-8
:    is a multi-byte (variable byte) encoding for unicode code points.

### How is UTF-8 stored?

7-bit ASCII is fully backward compatible and appears untouched. All other characters are multi-byte. They have a binary "header" starting with '1' appearing for the number of subsequent bytes followed by a '0', followed with data bits for the rest of that byte. Subsequent bytes start with a binary "10" header and the next 6 data bits. This gives a good algorithm for validating UTF-8 strings. Anything that does not conform triggers an "invalid UTF-8 character" exception.

    1-byte char: 0xxxxxxx
		2-byte char: 110xxxxx 10xxxxxx
		3-byte char: 1110xxxx 10xxxxxx 10xxxxxx
		etc., up to 6 bytes, though really only 4 are used currently

Source: wikipedia.org

### Sample UTF-8 Character: 

    Grapheme:      
    Name:          LATIN SMALL LETTER E WITH ACUTE
    Decomposition: LATIN SMALL LETTER E (U+0065) COMBINING ACUTE ACCENT (U+0301)
    Unicode:       u+00E9 (code point in hexadecimal, decimal 233)
    ASCII:         N/A
    Latin-1:       233 (ISO-8859-1)
    HTML:          &amp;eacute; &amp;#233; &amp;xe9; (number is Unicode code point)
    UTF-8:         0xC3A9 Binary: 11000011:10101001
    C/Ruby:        \u00E9

Sources: [fileformat.info](http://www.fileformat.info/info/unicode/char/e9/index.htm) [Wikipedia](http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references)


### Environment

UNIX Environments use the `locale` setting to identify your language preference, and character encodings for the console. Ensure yours are set to use UTF-8 when possible. 
Commands types at the command prompt will use this encoding, and so will most editors.

The BOM or [Byte Order Mark](http://en.wikipedia.org/wiki/Byte_order_mark) is the convention of placing 2 to 4 bytes as the first characters of the file to designate the endianness of the file as well as which Unicode specification is used. This should no longer be necessary in our new UTF-8 world.

Unicode supports a very large set of characters, but you still need fonts that represent those characters on your monitors and printers. When no character representation is available, you usually see a box with the hex codes inside in place of the character. If the character represents an invalid UTF-8 encoding you will see the "question mark in a diamond" symbol.

See your locale type:

    % locale charmap
	  UTF-8

### ICONV

[Character Encoding Translation](http://en.wikipedia.org/wiki/Character_encoding#Character_encoding_translation)
converts data from one encoding scheme to another. Under UNIX, the 
[iconv](http://en.wikipedia.org/wiki/Iconv) command and library converts files and input streams of data. First you should know the original encoding of the data. If you don't know, you can use the 
[file](http://en.wikipedia.org/wiki/File_(command)) command to guess it:

    $ file --brief --mime-encoding filename
    iso-8859-1

Here, it tells us we have a ISO-8859 file. 
(You can also use the [enca](http://linux.die.net/man/1/enca) command to guess and transform your file.)

Now let's convert it to UTF-8. The `-f` option is the "from encoding" and `-t` is for the "target encoding":

    $ iconv -f iso-8859-1 -t utf-8 < filename > filename.utf-8

Now, that file has been changed into UTF-8 encodings. Any letters with [diacritics](http://en.wikipedia.org/wiki/Diacritic) which took only 1 byte in Latin-1, now occupy 2 bytes as the corresponding Unicode character. 

Be careful, as not all characters from one one character set have a corresponding character in the target set. The [Unicode](http://en.wikipedia.org/wiki/Unicode) character set represents characters from all major writing systems in use today (but sadly, not [Klingon](http://en.wikipedia.org/wiki/Klingon_language)). 

If we were converting from Unicode to Latin-1, what happens to any non-Latin-1 characters, say some Chinese writing glyphs? They don't have a representation and therefore can not be properly converted. Hence is it also good to convert into Unicode, and not back into a more lossy format. 

Use the `-c` flag to `iconv` to silently discard such characters, though I don't have to tell you that isn't the best course of action.  If we did not give the discard option, the `iconv` command would stop at the point of that character. An alternate syntax is to append the "//IGNORE" string onto the target encoding name: 

    $ cat utf8file | iconv --from-code utf-8 --to-code iso-8859-1//IGNORE

If a character can't be represented in the target encoding, but can be approximated, this [transliteration](http://en.wikipedia.org/wiki/Transliteration) will appear to remove the diacritics off of vowels and change "" to "e". You can also append "//TRANSLIT" onto the target encoding name.

What I have demonstrated with the iconv command also applies to the iconv library and interfaces used in your application.

Japanese JIS and Shift-JIS encodings offer [problems](http://en.wikipedia.org/wiki/Japanese_language_and_computers) converting to UTF-8 losslessly. As a result many Japanese applications prefer the former encodings.

Microsoft Office files are stored as UTF-8 by default, but the user can change the encoding.

### Regular Expressions

[Unicode Regular Expressions](http://unicode.org/reports/tr18/) have extensions to grok the different character sets present. 
The [regular-expressions.info unicode](http://www.regular-expressions.info/unicode.html) page has a nice write-up about this.

The extension defines a new `\p{property}` syntax for matches to characters of the given properties. 
The inverse `\P{property}` or `\p{^property}` syntax matches characters not in the properties. The large list of properties include:

* Alphabetic
* Letter
* Lowercase
* Uppercase
* Hex_Digit
* alpha
* digit
* Whitespace

Or by character sets: Common, Latin, Hangul, Teragu, Thai, Cyrillic, Greek, Hebrew, Katakana, Hiragana, etc.

and they can be combines with advances syntax defines on the referenced pages. The full syntax is not supported in all regular expression engines (Perl, PGRE, Unigurama).

instead of 

    /^\w+/

which matches ASCII letters, digits and underscore, you could use:

    /^\p{Alphabetic}+/

which would match any character from any alphabetic, word, or symbolic language. Use the \p{property} syntax like any other character class: \w, \d, \s, etc.





### Collating sequence and Sorting

The Unicode specification includes the [Unicode Collation Algorithm](http://unicode.org/reports/tr10/).

Databases (PostgreSQL) have the collating sequenced defined when you create the database with a given encoding.

Unix utilities, such as sort, should respect the current locale setting. Since the file is not guaranteed to be in the same encoding as the locale, you may have to translate the encoding to the locale, or change the locale to match the file. 

I would expect the character "" to sort near the "a", but my tests place it after the ASCII characters, for both the OS X sort and postgres order by clause. 

    allen=# SELECT * from names order by 1;
    name  
    -------
     9999
     ZZZZ
     aaaa
     bbba
     cccc
     ~~~~
     
     
     
    (9 rows)





## Databases (PostgreSQL)

When you create a database, its default encoding is established. All character data should conform to that encoding. If you need to store non-character data in your database, use a "BLOB" (Binary Large Object) column type to hold binary data. To convert my PostgreSQL database, I do:

    $ createdb --encoding=utf-8 utf8db
    $ pg_dump asciidb | iconv -f iso-8859-1 -t utf-8 | psql utf8db

This creates a new database with the specified encodings (UTF-8 is now the default). It dumps the asciidb (as SQL commands), pipes the data through iconv which translated it into UTF-8, and executes and data are loaded into the utf8db. Since every 8-bit ISO-8859 character maps to a valid UTF-8 character, and if you have UTF-8 data stored in your database already, it will be double-encoded and be munged.

Before inserting any string into the database, know where it came from and its encoding.
When I run my application and attempt to send 8-bit characters to the database, it raises the following error:

    ERROR:  invalid byte sequence for encoding "UTF8": 0xf66e6967

Unlike Latin-1 and other 8-bit encodings, UTF-8 does not accept every binary combination as a valid character. Standard 7-bit ASCII is valid UTF-8, but 8-bit extended characters will most likely trigger this error when UTF-8 tries to read the next byte as the extension of the first.

PostgreSQL counts character in string lengths instead of bytes. Therefore you can put any UTF-8 character in a char(1) column, even if it is several bytes long.

NOTE: MySQL behaves differently when inserting invalid UTF-8 data: it silently truncates your data from the first bad character. MySQL considers the operation a success, but I would not, and neither should you!

Configure your database connection to return UTF-8 encoded strings. In Perl, set the `pg_enable_utf8=>1` option on the DBI::connect. For ActiveRecord (Ruby/Rails), use the `encoding: unicode` option. PHP: `options='--client_encoding=UTF8'` in the pg_connect string.




## Web Server

Configure your web server and applications to specify the UTF-8 character encoding:

    Content-Type: text/html; encoding=UTF-8
    Accept-Charset: utf-8
    
Most modern browsers respond in the same character set encoding as the current page. You can set the encoding in your web browser or application configurations (php.ini, etc.) The `Accept-Charset` HTTP header also specifies how the response (form submission) should be encoded. Sadly, a lot of older browsers out still ignore these working rules.

NOTE: Uploaded text files are not re-encoded in the given character set. The MIME `Content-Type` header for the "part" should have the encoding, but don't count on it. 

### API Considerations

Web forms are submitted from a web page with your encoding and charset specified in the HTTP Headers (and/or HTML). API Requests do no respond to your web page, they are the originator, and control the encoding and charset.

You can state up front that you only guarantee results with UTF-8 data, but an API meant to be used my many people will have this requirement ignored, as they won't understand the ramifications like you do!

Consider inspecting the data for your API request, detecting the encoding, and translating to UTF-8 when it is not 7-bit or UTF-8. IF you do receive UTF-8 data, do not "double-encode" it, as it can interpret multi-byte characters and individual binary characters and munge the incoming data.







## Email Systems

Email systems are still mostly (7-bit) ASCII applications. SMTP, the email transfer protocol, should only be sending 7-bit characters on lines that are only up to 76-characters long.

To get around the character set and encoding problems, MIME uses `Content-Transfer-Encoding` on body parts and attachments. The body part is encoded as [Quoted-Printable](http://en.wikipedia.org/wiki/Quoted-printable) which escapes non-ASCII characters as their hexadecimal code, or [Base64](http://en.wikipedia.org/wiki/Base64) which represents binary data as 7-bit characters. The contents themselves can be UTF-8 or anything else. The MIME parts themselves still need the appropriate `Content-Type` header specifying the MIME-Type and character encoding.

Email headers, as well as the MIME headers defining the body parts (such as attachment file names) must also be in 7-bit ASCII, but can not be transfer-encoded. Words within the "value" of the Email/MIME Headers can be transfer-encoded using the `MIME encoded word` format: "=?charset?encoding?encoded text?=", where:

* "Charset" is the name of the encoded character set
* "Encoding" is the `Content-Transfer-Encoding` type of the data word(s), "Q" for Quoted-Printable, "B" for "Base64"
* "Encoded Text" is the value in Quoted-Printable or Base64 representation.

And example and translation:

    Subject: =?iso-8859-1?Q?=A1Hola,_se=F1or!?=
    Subject: Hola, seor!

In these cases, when you decode the header value, the result may not be in UTF-8 and needs to be encoded as such. Fortunately, the MIME word encoding includes the original character set encoding! In a nutshell, take the data payload, decode it into a binary string according to the QP or Base64 rules, and pass it through iconv to translate from the given encoding into UTF-8.

Consider passing incoming raw email messages through a converter to UTF-8. If it is 7-bit ASCII, then nothing changes, but I have have found lots of Latin-1 characters in email not being properly escaped, causing UTF-8 errors later in processing. This is especially useful when loading a mailbox of old messages into your database.


### Email Addresses

[Email addresses](http://en.wikipedia.org/wiki/Email_address#Internationalization) should be 7-bit ASCII, but are now becoming internationalized. Since SMTP requires 7-bit characters, what happens? There is a lot of debate ongoing. Consider the SMTP conversation to deliver email to:

    RCPT TO: Pel@soccer.com
    
as a SMTP recipient address (Email Data in the To: header is separate from the SMTP "envelope" address which tells who the email gets sent to.) Most email servers don't handle addresses well at this UTF-8 level. It is best not to use them. I also believe any internet address (email, domain, etc.) should be accessible to anyone at the least common denominator: 7-bit ASCII. 

How are you validating email addresses? Are you expecting UTF-8 values? 

Domain names can also have UTF-8 characters in them now, more on that next.




## DNS

[Internationalized domain names](http://en.wikipedia.org/wiki/Internationalized_domain_name) are here! 

    http://.ws/

How can I type that? The IDN can be translated to ASCII using the [Punycode](http://en.wikipedia.org/wiki/Punycode) method.

That domain is real! Visit [http://.ws/](http://.ws/) It takes you to a domain registrar (randomly chosen, I can't vouch for them yet), but also with a punycode converter.

The algorithm is confusing. 
* Prepend domain with "xn--"
* Remove all non-ASCII characters
* If characters removed, append a "-"
* Generate the punycode numbers for the non-ASCII and append to the domain name. Details in the Punycode page.

The above domain appears as `http://xn--55gaaaaaa281gfaqg86dja792anqa.ws/` in punycode.

Another example domain: "bcher"  "bcher"  "bcher-"  "bcher-kva" would be `http://xn--bcher-kva.com`.



## Search Engines

When you google the term "pinata", it will return results for "piata."  Searches match internationalized characters with ASCII alternative. 

When inserting data into your search engine, consider running it through a transliteration for Latin encodings letters, and store them as "simplified ASCII" strings. 
Translate the search terms similarly, so you can match search terms in any related language. Be careful not to remove non-letter symbols.





## HTML
Web browsers expect your encoding to be set in the HTTP header. If you are using an encoding close enough to ASCII, you can override this in your `<HEAD>`:

    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">

UTF-8 Data in the HTML document can appear with UTF-8 encoding, or in the HTML Entity Number (&amp;#233;) syntax, but there should be no reason to escape it as such. HTML Entity names such as &amp;eacute; should remove the dependency of the number in the current encoding character set.

### The Rails Snowman! 

Ruby on Rails v3 introduced the [Rails Snowman](http://railssnowman.info/) to solve the IE encoding problem. Read more about it there. By including a throw-away field with a UTF-8 character, it will prevent the browser from deciding to send the request in another encoding. Since its cute introduction, the character has been changed to a check mark.   

Rails adds this extra input field to trigger UTF-8 in older IE browsers:

{% highlight html %}

    <form accept-charset="utf-8" action='/posts' id='create-post' method='post'>
        <input name="_utf8" type="hidden" value="&#9731;">
    </form>

{% endhighlight %}






## Javascript

Javascript 1.3 brought unicode support. If your source file contains non-ASCII characters, be sure to specify the charset on the script tag:

    <script type="text/javascript" src="javascript.js" charset="utf-8">








## Ruby 1.8

Ruby 1.8 had good Unicode support, but that has been made better in Ruby 1.9 (see below).

Ruby source code is assumed be be ASCII. If you want to use UTF-8 variable names and string literals, put the `encoding` hint on the second line:

    #!/usr/bin/env ruby -wKU
    # encoding:  UTF-8

To enable Unicode/UTF-8 support, start ruby with the `-KU` switch or set the global `$KCODE` variable:

{% highlight ruby %}

$KCODE = "UTF-8"

{% endhighlight %}

Since this is a global setting, you can not easily mix encodings within a single application.

Ruby's regular expression engine handles several different encodings: None (n), EUC (e), Shift JIS (s) and UTF-8 (u). The letter in parenthesis is the flag to append to the regular expression to get it to work.

{% highlight ruby %}

text = "Rsum"      # => "R\303\251sum\303\251" 
text.length          # => 8 
text.chars.each {|c| a << c}; a # => ["R", "\303", "\251", "s", "u", "m", "\303", "\251"] 

text.match /^\w+/    # => #<MatchData "R"> 
text.match /^\w+/u   # => #<MatchData "R\303\251sum\303\251">

$KCODE = 'UTF-8'
text.length          # => 8
text.chars           # => #<Enumerable::Enumerator:0x1010be198> 
text.chars.count     # => 6
text.chars.each {|c| a << c}; a # => ["R", "", "s", "u", "m", ""] 
text.match /^\w+/    # => #<MatchData "Rsum">

{% endhighlight %}

Ruby also has the Iconv library to convert between encodings, much like the `iconv` command:

{% highlight ruby %}

require "iconv"
text = "Rsum"
text.size  # => 8
begin
  latin1 = Iconv.conv("LATIN1", "UTF-8", text) # => "R\351sum\351" 
  rescue Iconv::InvalidEncoding  =>e
  rescue Iconv::InvalidCharacter =>e
end
utf8_to_latin1 = Iconv.new("LATIN1//TRANSLIT//IGNORE", "UTF-8")
latin1 = utf8_to_latin1.iconv(text)
latin1.size  # => 6

{% endhighlight %}

See James Edward Gray II's blog about [Understanding M17N](http://blog.grayproductions.net/articles/understanding_m17n) for more details.

See the Ruby 1.9 / Detetion of character encoding section for information on that topic.

## Ruby 1.9

In Ruby 1.9, all strings are encoded, and each string can have a different encoding. The `$KCODE` variable is no longer needed.

{% highlight ruby %}

utf8_text = text = "Rsum"
str = "\u9731"     # a snowman?
text.encoding.name # => UTF-8
text.size          # => 6
text.bytesize      # => 8
text[2..4]         # => sum
text.upcase        # => "RSUM"

{% endhighlight %}

The pseudo-encoding "BINARY" simply means any 8-bit byte/character and treat it as bytes, not characters. Here are some other games we can play with encodings:

{% highlight ruby %}

ascii_abc = abc = "abc"
abc.encoding.name                    # => US-ASCII
abc.encode("ASCII", undef: :replace) # => "R?sum?"
abc.force_encoding("UTF-8")
abc.encoding.name                    # => UTF-8
abc.valid_encoding                   # => true
png_data.force_encoding("BINARY")

Encoding.compatible?(ascii_abc, utf8_text) # => #<Encoding:UTF-8>
together = ascii_abc + utf8_text
together.encoding.name               # => UTF-8

text.match(/^\p{Latin}$/)            # => is latin?
text.match(/^\p{^Cyrillic}$/)        # => is not Cyrillic

p 'abc'.scan(/[\u0370-\u30FF]/)  # unicode codepoints from Greek to Katakana blocks		
{% endhighlight %}

Since we are character-aware, we have new iterators for the string.

{% highlight ruby %}

text.each_char {|c| puts c}
text.each_byte {|i| puts i}
text.each_line {|l| puts l}
text.bytes # => [82, 195, 169, ...]
text.chars.find { |char| char.bytesize > 1 }

{% endhighlight %}

Files: Default encodings from EnvironmentL `$LC_CTYPE`. We can read from files of a non-UTF-8 encoding and have Ruby do the conversion for us.

{% highlight ruby %}

open(infile, "r:UTF-8")        # Append :encoding to mode
open(infile, "r:LATIN1:UTF-8") # From ISO-8869-1 to UTF-8

utf = File.read("resume.utf8").chomp  # => "Rsum" 
utf.valid_encoding?           #  => true 
rutf.encoding                 # => #<Encoding:UTF-8> 
		
lat = File.read("resume.latin1").chomp  # => "R\xE9sum\xE9" 
lat.valid_encoding?  # => false 
lat.encoding # => #<Encoding:UTF-8> 

{% endhighlight %}

Additional information can be found at the [Regular Expression](http://www.regular-expressions.info/unicode.html) site.

{% highlight ruby %}

/asdf/u.encoding.name          # => "UTF-8" 
text = "Rsum"
text.match(/^\w+/)[0]          # => "R"
text.match(/\p{Word}+/)        # => "Rsum"      

{% endhighlight %}

You can set the internal and external encoding with the -E option. Data will be converted from the external to the internal encoding. 

    ruby -E external:internal
    ruby -E Shift_JIS:UTF-16LE

### Detecting the Encoding

Use the [rchardet](http://rubygems.org/gems/rchardet)/[rchardet19](http://rubygems.org/gems/rchardet19) gem to detect the encoding of a suspicious string.
Select rchardet for the Ruby 1.8 version, and rchardet19 for Ruby 1.9. 

    $ gem install rchardet

To use:

{% highlight ruby %}

cd = CharDet.detect(some_data) # => {"confidence"=>0.813842214321461, "encoding"=>"ISO-8859-2"} 
data = cd['confidence'] > 0.6 ? Iconv.conv(cd['encoding'], "UTF-8", data) : data

{% endhighlight %}
	

For Ruby 1.9:

    $ gem install rchardet19

To use:

{% highlight ruby %}

cd = CharDet.detect(some_data) # => #<struct encoding="ISO-8859-2", confidence=0.813842214321461>
data = cd.confidence > 0.6 ? Iconv.conv(cd.encoding, "UTF-8", data) : data

{% endhighlight %}


## Perl

Perl supports Unicode and other encodings on input and output with the [Encode](http://perldoc.perl.org/Encode.html) library. When you read or accept data into a Perl program, you should decode() it into Perl's internal format. The internal format has a UTF-8 flag so it knows the data contains  multi-byte characters, and will be treated in "character mode" instead of "byte mode."  Full details are available at the [Perl Unicode](http://perldoc.perl.org/perlunicode.html) page.

When writing or sending any data, you should encode() it into the desired encoding. You can enable UTF-8 support with the `perl -cs` option or the `PERL_UNICODE=S` environment variable.

Perl has two subtle UTF-8 encoding modes. `UTF-8` is strict compatibility (use this!), and `UTF8` (without the hyphen) is the relaxed mode. Do not use the relaxed mode.

Let Perl know if your Perl source code includes UTF-8 characters in variable names, literal strings, etc.:

{% highlight perl %}

use utf8;

{% endhighlight %}

Perl interally stores strings with a "UTF-8 Flag." If set, it will operate on the string (length, substr, etc.) as characters instead of bytes. Before doing this type of operation, ensure your Unicode string's UTF-8 flag is set by one of:
* Database connection on data returned (DBI::connect pg_enable_utf8=>1)
* Read string from a file with a :utf8 layer enabled
* String is decoded from an encoding (including UTF-8) into the internal format

If you get "invalid UTF-8 character" or "wide character" errors, check that the string has been passed through one of these methods. "Wide character" warnings appear when a multi-byte character is written to a file or stream without the :utf8 layer.

To work with UTF-8 data:

{% highlight perl %}

use Encoding qw(encode decode from_to);
use Encode::Detect::Detector;      # Used to detect the encoding

  # I know my input is in UTF-8
my $data = <INPUTFILE>;
my $name = decode('UTF-8', $data); # decodes into internal format
$name =~ s/\W//g;                  # Remove non-word characters with 
print encode('UTF-8', $name);

  # I Don't know the encoding
my $sender_email = $ENV{SENDER};   # Sender email address
my $encoding_name = Encode::Detect::Detector::detect($sender_email);
my $email = decode($encoding_name, $sender_email);
print encode('UTF-8', $email);
my $subject = decode('MIME-Header', $mime_word_encoded_subject); # Returns UTF-8

{% endhighlight %}

File encodings can be specified on the `open` function or with `binmode` on console streams. Data is automatically decoded on input and encoded on output. Perl calls this a "layer" on top of the file. Layers can be ":raw" (binary), ":utf8", or ":encoding(name)". The encoding() format validates the data is in the proper encoding.

{% highlight perl %}

    open my $infile "<:encoding(utf-8)", $infile or die;
    binmode STDOUT, ":utf8";

{% endhighlight %}



## PHP

PHP 6 is expected to have Unicode support baked in. Versions before that are tricky as the string functions operate on bytes instead of characters.

UTF-8 is not enabled by default. In your `php.ini` file, set:

    default_charset = "utf-8"

PHP has the Multi-Byte (MB) and iconv library functions to help work with character encodings.

{% highlight php %}

$utf8text = iconv("UTF-8", "ISO-8859-1//TRANSLIT", $text);
$encoding = mb_detect_encoding($text); # returns encoding name or False

{% endhighlight %}
    
Check out the PHP [Multibyte String](http://php.net/manual/en/book.mbstring.php) page for a full list of functions that operate on Multi-byte characters in strings.

## Bibliography

* [UTF-8: The Secret of Character Encoding](http://htmlpurifier.org/docs/enduser-utf8.html)
* [List of HTTP header fields](http://en.wikipedia.org/wiki/List_of_HTTP_header_fields)
* [Unicode](http://en.wikipedia.org/wiki/Unicode)
* [JEG2: Character Encodings](http://blog.grayproductions.net/categories/character_encodings)
* [Yehuda: Ruby 1.9 Encodings](http://yehudakatz.com/2010/05/05/ruby-1-9-encodings-a-primer-and-the-solution-for-rails/)
* [Yokolet Ruby 1.9 Unicode Regular Expression]( http://yokolet.blogspot.com/2008/09/ruby-19s-unicode-regular-expression.html)

