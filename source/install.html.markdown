---
title: Installation and Dependencies
---
`riak-client` requires i18n, builder, beefcake, and multi_json. The
cache store implementation requires ActiveSupport 3 or later.

## Ruby Versions

Ruby 1.9.3, 2.0, and 2.1 are supported. JRuby in 1.9 and 2.0 modes are
also supported. `riak-client` is not compatible with Ruby 1.8.

In JRuby 1.7.13, OCSP validation is absent, and CRL validation always
fails. [This issue is being tracked][1] and this document will be updated when
it is fixed. Additionally, client certificate authentication doesn't work in
JRuby. [This issue is also being tracked][2], and this document will be updated
when it works.

[1]: https://github.com/jruby/jruby-openssl/issues/5
[2]: https://github.com/basho/riak_api/issues/65

## Installing

We *highly* recommend using [Bundler][3] to manage your application or library's
dependencies.

First, add the dependency declaration to your `Gemfile`:

```ruby
gem 'riak-client', '~> 2.0.0'
```

Next, run the `bundle` command to install a version of the gem:

```bash
$ bundle
```

[3]: http://bundler.io

## Updating

Make sure the `Gemfile` line includes the version you wish to update to. For
example, this declaration uses the "pessimistic version constraint" to
specify that versions 2.0.1, 2.0.2, etc. are valid, but not 2.1.0 or
3.0.0:

```ruby
gem 'riak-client', '~> 2.0.0'
```

Visit the Rubygems documentation for [more information about dependency
declarations.][4]

To actually install an updated version:

```bash
$ bundle update riak-client
```

The Riak Ruby Client use [semantic versioning][5]. 2.0.0 included
breaking changes, 2.1.0 will include new functionality, and 2.0.1 will simply be
bug fixes.

[4]: http://guides.rubygems.org/patterns/#declaring-dependencies
[5]: http://semver.org

## Development Dependencies

Development dependencies are handled with bundler. Install bundler
(`gem install bundler`) and run this command to get started:

```bash
$ bundle install
```

Run the RSpec suite using `bundle exec`:

```bash
$ bundle exec rake
```
