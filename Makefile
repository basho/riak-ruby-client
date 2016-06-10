.PHONY: release

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

# NB:
# VERSION does NOT include the v suffix

release:
ifeq ($(VERSION),)
	$(error VERSION must be set to build a release and deploy this package)
endif
ifeq ($(RELEASE_GPG_KEYNAME),)
	$(error RELEASE_GPG_KEYNAME must be set to build a release and deploy this package)
endif
	@rm -rf pkg
	@bash ./build/publish $(VERSION) validate
	@sed -i'' -e 's/VERSION.*/VERSION = "$(VERSION)"/' ./lib/riak/version.rb
	@rake package
	@git commit -a -m "riak-client $(VERSION)"
	@git tag --sign -a "v$(VERSION)" -m "riak-client $(VERSION)" --local-user "$(RELEASE_GPG_KEYNAME)"
	@git push --tags master
	@gem push "pkg/riak-client-$(VERSION).gem"
	@bash ./build/publish $(VERSION)
