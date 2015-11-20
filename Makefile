.SILENT:
.PHONY: help

## Colors
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[33m

## Package
PACKAGE_VERSION = 1.9.4-1

## Package - Source
PACKAGE_SOURCE = https://github.com/ansible/ansible/archive

## Help
help:
	printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	printf " make [target]\n\n"
	printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	awk '/^[a-zA-Z\-\_0-9\.@]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf " ${COLOR_INFO}%-16s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

## Build
build: build-packages

build-packages:
	docker run \
	    --rm \
	    --volume `pwd`:/srv \
	    --workdir /srv \
	    --tty \
	    debian:wheezy \
	    sh -c '\
	        apt-get update && \
	        apt-get install -y make && \
	        make build-package@debian-wheezy \
	    '

build-package@debian-wheezy:
	apt-get install -y wget python python-setuptools devscripts cdbs asciidoc python-support
	# Get origin package
	wget --no-check-certificate ${PACKAGE_SOURCE}/v${PACKAGE_VERSION}.tar.gz -O ~/package.tar.gz
	# Extract origin package
	mkdir -p ~/package
	tar xfv ~/package.tar.gz -C ~/package --strip-components=1
	# Build package
	cd ~/package && make deb
	# Move package files
	mkdir -p /srv/files/debian_wheezy
	rm -f /srv/files/debian_wheezy/*.deb
	mv ~/package/deb-build/unstable/ansible_*.deb /srv/files/debian_wheezy/ansible_${PACKAGE_VERSION}_all.deb
