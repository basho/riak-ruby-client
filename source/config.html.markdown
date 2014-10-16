---
title: Configuration
---
Riak Ruby Client supports many different configuration options, for many kinds
of configuration setting.

## Connecting

The simplest way to connect assumes Riak is listening for Protocol Buffers on
`localhost:8087`:

```ruby
c = Riak::Client.new
```

If Riak is listening on a different protobuffs port:

```ruby
c = Riak::Client.new pb_port: 17017
```

Or on another machine:

```ruby
c = Riak::Client.new host: 'riak.example'
c = Riak::Client.new host: 'riak.example', pb_port: 17017
```

If you have multiple Riak nodes you want the client to use, you can set them up:

```ruby
c = Riak::Client.new(nodes: [
    {host: 'riak1'},
    {host: 'riak2', pb_port: 17017},
    {host: '10.0.5.61', pb_port: 17017}
])
```

## Security

Riak 2 adds support for secure Protocol Buffers. To enable this, add an
`authentication` hash to your connection parameters.

For password-based authentication, you'll use something like this:

```ruby
c = Riak::Client.new(authentication: {
  user: 'zedo', # required for all authentication, /do not/ use `username`

  # required if your Riak cluster doesn't have a system-recognized certificate
  ca_file: "/etc/ssl/certs/corporate_ca.crt",

  password: 'catnip', # required for password-based authentication  
})
```

For more-secure but harder-to-administer client certificate authentication,
configure a client certificate and key:

```ruby
c = Riak::Client.new(authentication: {
  user: 'zedo', # required for all authentication, /do not/ use `username`

  # required if your Riak cluster doesn't have a system-recognized certificate
  ca_file: "/etc/ssl/certs/corporate_ca.crt",

  # client-cert parameters support filenames, OpenSSL-compatible string data,
  # or properly initialized OpenSSL objects
  client_ca: '/etc/ssl/certs/corporate_client_ca.crt', # filename
  cert: File.read('/etc/ssl/certs/my_client.crt'), # string data
  key: OpenSSL::PKey::RSA.new(File.read('/etc/ssl/keys/my_client.key')) # object
})
```

## Client ID

In some cases you might want to provide a specific client ID for your instance
of the Riak client:

```ruby
c = Riak::Client.new client_id: 1234567890
