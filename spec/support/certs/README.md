**DO NOT USE THESE IN PRODUCTION**

This directory has certificates and a key for testing Riak authentication.

* server.key - a private key for a Riak server
* server.crt - the certificate for server.key
* ca.crt - a certificate for the CA that issued server.crt
* empty_ca.crt - a certificate for a CA that has and cannot ever issue a 
  certificate (I deleted its private key)

**DO NOT USE THESE IN PRODUCTION**

These were generated using https://github.com/basho-labs/riak-ruby-ca .