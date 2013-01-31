---
layout: post
title: "Email Addresses in Applications"
date: 2013-01-31 15:34
comments: true
categories: 
---

As an application developer or stakeholder, you may require an email
address during registration that will maintain the user's identity. 
Email addresses are complicated beasties, and can leave you with a set
of problems properly locating an account for support. Also, you may want
to track if multiple user accounts refer to the same email account.

Adhering to RFC specification for email address may not help, and
indeed could complicate matters. It takes a lot of leeway in
what addresses are valid. Too much leeway.

As with any data input by the user, the email address needs to be
edited, validated, and verified.

One technique to use is *normalization*, a process of stripping spaces,
changing the address to a standardized character subset such as
lower-case, and ensuring it is well formed.

Another concern is uniqueness of an email address within your
application, where you can map multiple user account to a single email
account. You can apply special editing rules to create an *canonical* email address.

Consider this address:

    ALan.TURing+howdy@example.COM

The normalized version could be

    alan.turing+howdy@example.com

and the canonical address could be:

    alanturing@example.com


### TLDR;

The RFC specification for email addresses allows for some crazy
addresses you may not want to support. These edge cases should never be
used in a practical email address, and could give you support
nightmares.

  * Decide what parts of the specification you wish to support. You can find that almost all addresses fall in a simpler scheme, and the others are likely to be computer-controlled addresses, spam, or plain junk.  
  * Keep address tags (`mailbox+info@example.com`) the user give you.
  * Consider keeping a canonical form for account recovery and
    searching.


### RFC Email Addresses

Email addresses are of the format "mailbox@hostname", where the *mailbox*
is usually a user account, application, or system role account, but can also contain
further routing information or identifiers used for sorting, application, or
tracking purposes. 

The *hostname* is usually a domain name, but can refer to a node, either a subdomain, server, service, IP address, or computer host.

#### Valid Mailbox Names

The RFC Spec allows some pretty strange email addresses. As with the
discussion on mixed-case email addresses, it could be disadvantageous to
support them as they are too complex, generally not reproducable without
knowledge of how to encode them by humans. Consequently, they are a
burden to support staff and proabably never used in the wild except for
rare cases.

Mailboxes can have spaces. If I remember correctly, pre-internet AOL
allowed spaces in their "screen names", which were then used as mailbox
names with the spaces removed: screenname@aol.com -- though by RFC, you
can use double-quotes around mailboxes with names: 

    "Alan Turing"@example.com

Using this method, even a mailbox name of a single space is valid, when
quoted.

Here is a valid email address created from the odd characters allowed in
the mailbox:

    !#$%&'*+-/=?^_`{}|~@example.com

Even if you decide to accept simple email addresses (as anything else is
most likely a mail bot, spam etc.), remember to include the apostrophe
in the address:

    Miles.O'Brian@example.com

This does not need to be quoted or escaped for email, but certainly when
storing in your database or passing around your system.

Find out more at the wikipedia article on
[Email Addresses](http://en.wikipedia.org/wiki/Email_address#Valid_email_addresses).

Do you need full RFC compliance? It's your choice, but I suggest that
you don't. Having spaces and odd characters in your email addresses
is not standard practice, and most likely occur from typing errors. The
major email providers do not allow them in their addresses, most likely
for the same reason. You should be safe enough only allowing letters,
digits, and the period, underscore, hyphen, and plus characters.

#### Case Sensitive Mailbox Names

By RFC, email addresses are unique by mixed-case. Most (99.9+%) email systems do
not treat email addresses as such, accepting email for `allen@example.com` or
`ALLEN@example.com` as the same address. These handful of strict systems
require specific capitalization such as `Allen@example.com` and will reject any
other combinations. 

This requirement never works well in practice, mostly because people
typing in your email address would not expect case sensitivity. If I told my friend to
email me at `Allen@example.com`, she would probably just use `allen@example.com`, or
if she was the kind of person that shouts, they would type
`ALLEN@EXAMPLE.COM` with the caps-lock key fully engaged. That email would
never reach me. 

Should you respect this part of the RFC? The choice is yours.
By converting all email addresses to lower-case, you will exclude all
users from specialty email systems that only work with an uppercase
character in the mailbox name.

Otherwise, the conversion of the email address to lower case would be a
good choice for normalization.

If you decide to keep the case of the email address as entered (`Allen@example.com`), 
and the user does not provide the address with the same case (`allen@example.com`), 
even if that address was not case-sensitive to its mail server, 
it would not match your database unless you store and check the canonical format.


#### Non-essential Mailbox Characters

Google's Gmail service provides an interesting twist for addresses.
While the use of periods as separators is encouraged, they have no
significance in the email address. These addresses refer to the same
mailbox.

    first.last@gmail.com
    firstlast@gmail.com
    f.i.r.s.t.l.a.s.t@gmail.com

Note: The Google Apps service allows a company to host their email on gmail with a private domain name. This technique would be available for these domains as well.

#### Extended Mailbox Names with Address Tags

Many email systems (MTA), including sendmail, postfix, qmail, yahoo
plus, and gmail allow an extended mailbox name. This allows the user to add a special
identifier to the address to help sorting email into different mailboxes. 

Most of these use the "+" symbol to separate the mailbox name
from the extended name. Qmail, by default, uses the "-" (hyphen) which
is not as easy to identify apart from non-qmail addresses.

Favorite uses for the extended mailbox allow easier mail filtering and
identifying where the email was used. For instance, when I register at a
web site such as amazon, I would give an address like `allen+amazon@example.com`. Then
I can filter my amazon mail to a special folder, or notice when a
third-party started emailing me with that address. I can also
effectively cancel that extended address by creating a filter to drop
it.

This would also allow me to create multiple accounts on your
application, `allen+one@example.com` and `allen+two@example.com`.

Should you remove the extended mailbox name? No! Be friendly to your
users and keep it there in good faith that you do not intent to sell or
share that address. Even if you are trying to prevent me from creating
an additional account, It wouldn't be too hard for me to create another
email address to get in anyway.

If I registered with an extension, and later don't remember I used one, I
would not be able to sign in using my `allen@example.com` address. This
is where keeping a canonical version of the email address would be
handy. I could lookup my account ("forgot password") with 
any extended mailbox name, which would be used to match by canonical
address instead of the registered address.

#### Unicode and Internationalized Mailbox Names

Mailbox names do not support extended (8-bit) ASCII codes and Unicode characters. 
This limitation belongs to SMTP, which does not specify a character set
on the "RCPT TO" command, it assumes 7-bit only. Perhaps, it can take a
locally-defined 8-bit extension, perhaps a character in some ISO-8859-x
character set, but you store your data in Unicode--I hope. There is no
method to specify a character set in SMTP.

### Email Domain Names

Email domain name restrictions are the same as HTTP domain names. They
are not case sensitive, so you can normalize them in lower-case
characters. 

#### Subdomains

Some email addresses contain unnecessary subdomains. For instance,
`email.msn.com` and `msn.com` are the same address. Otherwise, you may
find these addresses mostly on corporate email addresses.

#### International Domain Names (IDN)

[International Domain Names](https://...)
were created to handle domain names for some top-level domains to
include local Uncicode characters for locale. 
You can also create a domain name with special characters as such:

    postmaster@☁→❄→☃→☀→☺→☂→☹→✝.ws

which nicely describes the water cycle. 

As with HTTP, SMTP only supports
the 7-bit ASCII character set. To handle this, IDN's are converted to a
[Punycode](http://) encoding scheme, which allows the domain name to be
converted to and from its Unicode character representation.

    postmaster@xn--55gaaaaaa281gfaqg86dja792anqa.ws

There is also a spoofing consideration with IDN domain names. The
Unicode character set includes multiple versions of some ASCII letters. 
A fishing site could register a domain that looks like your banking
domain, replacing a letter with a look-alike Unicode.

So this raises a few questions for your application:

  * Should we accept IDN email addresses? Can your support staff handle
    these domain names (understand and type them on their keyboards)?
  * Should we store them in Unicode or Punycode? If you maintain a
    separate canonical form, what encoding should this be given?
  * How well does your MTA (mail server) support IDN's, or does it
    expect the domains to be converted to Punycode in advance.

#### IP Address syntax

It is allowed to specify an email address with an IP address:

    allen@[127.0.0.1]
    allen@[IPv6:0:0:1]

However these addresses make be too suspicous to use.

There is an older "Bang syntax" that was used before DNS systems became
popular. Instead of a final domain name, it used a routing path of host
names separated by a bang (!) symbol. I don't know if it is still
supported, but assume no one uses it anymore.

### Disposable email addresses

There are many services out there that provide people with a temporary
email address, usually for registration on sites that they do not trust
or that will send them unwanted spam. They will give the user an email
address as a special domain name and a web interface to accept email
from that account for a few minutes, enough to confirm a registration. 

Even traditional email services like Hotmail and Yahoo provide an
"alias" mailbox name that can be used in much the same way, then dropped
after a period of time.

There is no good method to detect what domains are disposable addresses.
After all, that is what they are designed to do. They use a large, constantly
changing, rotating set of domain names to stay ahead of sites trying to
crack them.

### The argument for accepting only a subset of valid addresses

Email addresses can be complex, and (a total guess) 99.99+% of addresses
follow simple address rules. The rest of the addresses are to complex to
support. 

The choices you must consider are rejecting addresses with either:

  * Case-sensitive mailboxes
  * Spaces in address (collapse spaces)
  * Quoted mailbox names or escaped symbols
  * Special characters other than `'._,+-`
  * IP Address domains
  * International Domain Names

While you may create a problem with a few people, they will generally
have another email address that conforms to normal usage. It will also
allow your staff to handle support and data issues regardless of the
locale.

I believe you should always respect mailbox extensions (address tags).

If nessessary, you can create another field with a canonical address,
even if you choose to use all RFC conformant addresses. This
canonical address would have:

  * Lower case
  * Eliminate mailbox extensions (address tags)
  * Transliterate Unicode characters to ASCII (remove accents,
    diagraphs, etc.)
  * Remove subdomain 

Create a canonical email routine to take an email address and return the canonical verion. Use this to store and lookup an address in your database
database or search engine. This should find an email address regardless of its
specializations.

### Storing both Normalized and Canonical Versions

