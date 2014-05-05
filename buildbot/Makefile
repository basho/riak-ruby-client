RIAK_CONF = ${RIAK_DIR}/etc/riak.conf
ADVANCED_CONF = ${RIAK_DIR}/etc/advanced.config
# RIAK = ${RIAK_DIR}/bin/riak
RIAK_ADMIN = ${RIAK_DIR}/bin/riak-admin
CERTS_DIR = $(shell pwd)/../riak-ruby-vagrant/certs

preconfigure:
	@git clone git://github.com/basho-labs/riak-ruby-vagrant.git
	echo "storage_backend = memory" >> ${RIAK_CONF}
	echo "search = on" >> ${RIAK_CONF}
	echo "listener.protobuf.internal = 127.0.0.1:8087" >> ${RIAK_CONF}
	echo "ssl.keyfile = ${CERTS_DIR}/server.key" >> ${RIAK_CONF}
	echo "ssl.certfile = ${CERTS_DIR}/server.crt" >> ${RIAK_CONF}
	echo "ssl.cacertfile = ${CERTS_DIR}/ca.crt" >> ${RIAK_CONF}
	echo '[{riak_api,[{keyfile,"${CERTS_DIR}/server.key"},{certfile,"${CERTS_DIR}/server.crt"},{cacertfile,"${CERTS_DIR}/ca.crt"}]}].' > ${ADVANCED_CONF}

configure:
	@${RIAK_ADMIN} bucket-type create counters '{"props":{"datatype":"counter", "allow_mult":true}}'
	@${RIAK_ADMIN} bucket-type create maps '{"props":{"datatype":"map", "allow_mult":true}}'
	@${RIAK_ADMIN} bucket-type create sets '{"props":{"datatype":"set", "allow_mult":true}}'
	@${RIAK_ADMIN} bucket-type create yokozuna '{"props":{}}'
	@${RIAK_ADMIN} bucket-type activate counters
	@${RIAK_ADMIN} bucket-type activate maps
	@${RIAK_ADMIN} bucket-type activate sets
	@${RIAK_ADMIN} bucket-type activate yokozuna
	@${RIAK_ADMIN} security add-user user password=password
	@${RIAK_ADMIN} security add-source user 127.0.0.1/32 password
	@${RIAK_ADMIN} security grant riak_kv.get,riak_kv.put,riak_kv.delete,riak_kv.index,riak_kv.list_keys,riak_kv.list_buckets,riak_core.get_bucket,riak_core.set_bucket,riak_core.get_bucket_type,riak_core.set_bucket_type,search.admin,search.query on any to user

compile:
	@cd ..; bundle install --binstubs --path=vendor

lint:
	@find .. -type f -name "*.rb" | xargs -n1 ruby -c

test: test-normal test-security

test-normal:
	@echo 'nodes:' > ../spec/support/test_client.yml
	@echo '  - { pb_port: 8087 }' >> ../spec/support/test_client.yml
	@echo "Test client config:"
	@cat ../spec/support/test_client.yml
	@cd ..; bin/rspec

test-security:
	@echo 'authentication:' >> ../spec/support/test_client.yml
	@echo '  username: user' >> ../spec/support/test_client.yml
	@echo '  password: password' >> ../spec/support/test_client.yml
	@echo "Test client config for security:"
	@cat ../spec/support/test_client.yml
	${RIAK_ADMIN} security enable
	@cd ..; bin/rspec --tag yes_security
