.PHONY: help all deps lint clean
.PHONY: test unit-test integration-test security-test
.PHONY: release gemspec_validat0

unexport LANG
unexport LC_ADDRESS
unexport LC_COLLATE
unexport LC_CTYPE
unexport LC_IDENTIFICATION
unexport LC_MEASUREMENT
unexport LC_MESSAGES
unexport LC_MONETARY
unexport LC_NAME
unexport LC_NUMERIC
unexport LC_PAPER
unexport LC_TELEPHONE
unexport LC_TIME

PROJDIR = $(realpath $(CURDIR))
TCY := $(PROJDIR)/spec/support/test_client.yml
CLIENT_CERT := $(PROJDIR)/tools/test-ca/certs/riakuser-client-cert.pem
CA_CERT := $(PROJDIR)/tools/test-ca/certs/cacert.pem

all: test

help:
	@echo ''
	@echo ' Targets:'
	@echo '-------------------------------------------------'
	@echo ' all              - Run everything               '
	@echo ' deps             - Install required gems        '
	@echo ' lint             - Run rubocop                  '
	@echo ' clean            - Clean local gems             '
	@echo ' test             - Run unit & integration tests '
	@echo ' unit-test        - Run unit tests               '
	@echo ' integration-test - Run integration tests        '
	@echo ' timeseries-test  - Run timeseries tests         '
	@echo ' security-test    - Run security tests           '
	@echo '-------------------------------------------------'
	@echo ''

deps: clean
	@gem install bundler
	@bundle install --binstubs --path=vendor --without=guard

lint:
	@bundle exec rubocop lib spec

clean:
	@rm -rf vendor/*
	@rm -f Gemfile.lock

unit-test:
	@bundle exec rake ci

integration-test:
	@cp -f $(TCY).example $(TCY)
	@bundle exec rake spec:integration

timeseries-test:
	@cp -f $(TCY).example $(TCY)
	@bundle exec rake spec:time_series

security-test:
	@cp -f $(TCY).example $(TCY) && \
		echo 'authentication:' >> $(TCY) && \
		echo '  user: user' >> $(TCY) && \
		echo '  password: password' >> $(TCY) && \
		echo "  ca_file: $(CA_CERT)" >> $(TCY)
	@bundle exec rake spec:security

test: lint unit-test integration-test

gemspec_validate:
	@bundle exec rake gemspec

release: gemspec_validate
# NB:
# VERSION does NOT include the v suffix
ifeq ($(VERSION),)
	$(error VERSION must be set to build a release and deploy this package)
endif
ifeq ($(RELEASE_GPG_KEYNAME),)
	$(error RELEASE_GPG_KEYNAME must be set to build a release and deploy this package)
endif
	@rm -rf pkg
	@$(PROJDIR)/build/publish $(VERSION) validate
	@sed -i'' -e 's/VERSION.*/VERSION = "$(VERSION)"/' $(PROJDIR)/lib/riak/version.rb
	@bundle exec rake package
	@git commit -a -m "riak-client $(VERSION)"
	@git tag --sign -a "v$(VERSION)" -m "riak-client $(VERSION)" --local-user "$(RELEASE_GPG_KEYNAME)"
	@git push --tags
	@git push
	@gem push "pkg/riak-client-$(VERSION).gem"
	@$(PROJDIR)/build/publish $(VERSION)
