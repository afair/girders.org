---
layout: post
title: "Don't RFC-Validate Email Addresses"
date: 2013-01-31 15:34
comments: true
categories:
---

Many applications require users to register or enter their email
addresses. As good, standards-compliant developers, we want to validate
and accept these email addresses using RFC standards. We think it
will help us in the future, and make our app a shining beacon of
usability to be admired.

Wrong.

<!--more-->

It sounds like a reasonable thing to want, and it should be. The problem
is that there is nothing reasonable about email address formats.  In fact,
adhering to RFC specifications for email addresses may not help, and
indeed could complicate matters.

Why? There is a lot of crazy in the way email addresses is specified.
Perhaps it came from letting different existing email systems
represented their account, to encompass anything that was valid before.
Email existed before DNS and before our modern email address format
`user@domain.tld`.  Before then, we had the UUCP
"[bang path](http://en.wikipedia.org/wiki/UUCP#Bang_path)" notation,
which lists each machine "hop" in the route to deliver the mail


### Anatomy of an email address

Email addresses are of the form:

    mailbox@hostname

Where a *mailbox* can be a local user account, role account, or routing
address to an automated system, such as a mailing list. Hostname is a
computer identified through DNS used to receive the message.

Additionally, some mail systems support
[address tags](http://en.wikipedia.org/wiki/Email_address#Address_tags),
usually of the format:

    mailbox+tag@hostanme

where the *tag* and its separator (usually "+", Qmail uses "-" by default,
but the symbol can be locally configured) are disregarded when
delivering the mail to the mailbox. This technique is used to help in
filtering mail to different folders and actions, as well as to identify
a version of the email address given during registration to track its
use and misuse.

Email addresses are of the format "mailbox@hostname", where the *mailbox*
is usually a user account, application, or system role account, but can also contain
further routing information or identifiers used for sorting, application, or
tracking purposes.

The *hostname* is usually a domain name, but can refer to a node, either a subdomain, server, service, IP address, or computer host.

### RFC Valid Mailbox Names

The RFC Spec allows some pretty strange email addresses. It would be disadvantageous to
support them as they are too complex, and generally not reproducible by humans without
knowledge of how to encode them. Consequently, they are a
burden to support staff and probably never used in the wild except for
rare cases.

Mailboxes can have spaces. If I remember correctly, pre-internet AOL
allowed spaces in their "screen names", which were then used as mailbox
names with the spaces removed: screenname@aol.com -- though by RFC, you
can use double-quotes around mailboxes with spaces:

    "Alan Turing"@example.com   <== Don't accept

Using this method, even a mailbox name of a single space is valid, when
quoted: `" "@example.com`

Here is another valid email address created from the odd characters allowed in
the mailbox:

    !#$%&'*+-/=?^_`{}|~@example.com   <== Don't accept

Even if you decide to accept simple email addresses (as anything else is
most likely a mail bot, spam etc.), remember to include the apostrophe
in the address:

    Miles.O'Brian@example.com  <== Must accept

This does not need to be quoted or escaped for email, but certainly when
storing in your database or passing around your system. Just ask
[Bobby Tables](http://xkcd.com/327/).

Read more at the wikipedia article on
[Email Addresses](http://en.wikipedia.org/wiki/Email_address#Valid_email_addresses).

Do you need full RFC compliance? It's your choice, but I suggest that
you don't. Having spaces and odd characters in your email addresses
is not standard practice, and most likely occur from typing errors. The
major email providers do not allow them in their addresses, most likely
for the same reason. You should be safe enough only allowing letters,
digits, period, underscore, hyphen, apostrophe, and plus characters.

### Case Sensitive Mailbox Names

By RFC, email addresses are unique by mixed-case. Most (99.9+%) email systems do
not treat email addresses as such. So these email addresses reach the
name mailbox when they are NOT case-sensitive:

    ALLEN@example.com
    Allen@example.com
    allen@example.com

The handful of strict systems require specific capitalization such as
`Allen@example.com` and will reject any other combinations.
This requirement never works well in practice, mostly because people
typing in your email address would not expect case sensitivity.

Should you respect this part of the RFC? 
By converting all email addresses to lower-case, you may exclude
a small fraction of users (or just be able to send them email).
I have worked with many millions of email addresses, and have only seen one of these.

Conversion of the mailbox to lower case would be a good choice for normalization
of your data.  The domain is not case-sensitive and should be lower-cased.

If you decide to keep the case of the mailbox as entered, store a
lower-case version in a second, canonicalized email address.


### Non-essential Mailbox Characters

Google's Gmail service provides an interesting twist for addresses.
While the use of periods as separators is encouraged, they have no
significance in the email address. These addresses refer to the same
mailbox.

    first.last@gmail.com
    firstlast@gmail.com
    f.i.r.s.t.l.a.s.t@gmail.com

Note: The Google Apps service allows a company to host their email on gmail with a private domain name. This technique would be available for these domains as well.

The problem with this is looking up the email address when a variant is
used for the initial registration. It could create a headache for
end-user and support staff alike.

This is where storing a second, canonical email address version would
serve you well. More on this later...

### Extended Mailbox Names with Address Tags

As discussed earlier,
many email systems (MTA), including sendmail, postfix, qmail, yahoo
plus, and gmail allow an extended mailbox name. This allows the user to add a special
identifier to the address to help sorting email into different mailboxes.

This technique would allow me to create multiple accounts on your
application: 

    allen+one@example.com
    allen+two@example.com

Should you remove the extended mailbox name? 

*No!* Be friendly to your
users and keep it there in good faith that you do not intent to sell or
share that address. Even if you are trying to prevent someone from creating
an additional account, it is never hard to create a new email account or
alias.

Again, this is where storing a second, canonical email address version would
serve you well. You store this version without any tags, and you can
lookup any address in its canonicalized format in your data store.

### Unicode and Internationalized Mailbox Names

Mailbox names do not support extended (8-bit) ASCII codes and Unicode characters.

This limitation belongs to SMTP, which does not specify a character set
in the protocol.  Perhaps, it can take a
locally-defined 8-bit value, like one of the ISO-8859-x character sets, 
but you don't know the encoding used. 

In fact, the only 8-bit email addresses I have seen are from spammers.

Since you store your data as Unicode in UTF-8 (right?), you can't
translate it back to the local encoding unless you knew that too.

### Email Domain Names

Email domain name restrictions are the same as HTTP domain names. They
are not case sensitive, so you can normalize them as lower-case
characters.

#### Subdomains

Some email addresses contain unnecessary subdomains. For instance,
`email.msn.com` and `msn.com` are the same address. Otherwise, you may
find these addresses mostly on corporate email addresses.

(Another candidate for a canonical address?)

### International Domain Names (IDN)

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
A fishing site could register a domain that looks like your 
domain, replacing a letter with a look-alike Unicode character.

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

However these addresses may be too suspicious to use or trust.

### Disposable email addresses

There are many services out there that provide people with a temporary
email address. They are used for anonymity or to generate a temporary 
address for registration on untrusted sites.

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

If necessary, you can create another field with a canonical address,
even if you choose to use all RFC-conforming addresses. This
canonical address would have:

  * Lower case
  * Eliminate mailbox extensions (address tags)
  * Transliterate Unicode characters to ASCII (remove accents,
    diagraphs, etc.)
  * Remove subdomain

While this advice may seem extreme, it is more practical than obeying
the standards. Could this even influence the edge cases of the internet 
to embrace this simplified usage as well?

### Bonus: Tracking Deleted Email Addresses

When someone deletes their account or email address from your app, it is
good practice to delete from your data stores as well. That way, any
compromise wouldn't open any spam to your ex-users. 

Unfortunately, it may not always be practical to do this. Irate users
may demand you delete their address and never contact them again. If you
remove the address, how do you know it can't be re-added (by someone
else)?

In this case, try converting the email address to its MD5 (or similar) equivalent
and storing as the mailbox, retaining the domain for conflict
resolution.
You can't reverse the email address, but you can check to see if it is
in the known list of previous addresses.

    allen@example.com     <= Before
    785ee39055efcd86359b6e05a9bef0e7@example.com  <= After

Then have your app check this version of the email address to match
against an incoming request.
