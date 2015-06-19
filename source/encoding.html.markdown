---
title: Character Encodings
---
Ruby has flexible and powerful support for many different character encodings,
including UTF-8, Shift-JIS, and more. Not every sequence of bytes has a
character encoding though, and Ruby provides an "ASCII-8BIT" encoding (also
known as "binary") that takes any sequence of bytes as valid.

```ruby
"您好".encoding #=> #<Encoding:UTF-8>
"您好".valid_encoding? #=> true
"\xff\xff".encoding #=> #<Encoding:UTF-8>
"\xff\xff".valid_encoding? #=> false
"\xff\xff".force_encoding('binary').valid_encoding? #=> true
```

For more information about encoding in Ruby, check out
[the Ruby API documentation][3], [the Wikibooks page][2], and
[James Edward Gray II's series about character encoding][4].

[3]: http://ruby-doc.org/core-2.2.2/Encoding.html
[2]: https://en.wikibooks.org/wiki/Ruby_Programming/Encoding
[4]: http://graysoftinc.com/character-encodings/understanding-m17n-multilingualization

Different parts of Riak have differing support for different byte sequences and
character encodings; the results of our testing with UTF-8 and binary strings
are below.

These findings were tested with Riak 2.1.1 using the [riak-ruby-vagrant][1]
environment.

[1]: https://github.com/basho-labs/riak-ruby-vagrant

If you are curious about other character encodings, please let us know: we would
love to help you write better Riak-using software.

## Key-value

Testing shows that key-value operations work with UTF-8 and arbitrary binary
strings.

## CRDTs

Riak CRDTs have been tested successfully with UTF-8 and arbitrary binary
strings.

## Riak Search

Riak Search (a.k.a. Yokozuna) is strict about characters. Not all valid
UTF-8 strings (and by extension, not all valid binary strings) are acceptable
names for indexes or schemas.

In addition, objects with keys or buckets that aren't ASCII 7-bit safe might
not be indexed by Riak Search.
