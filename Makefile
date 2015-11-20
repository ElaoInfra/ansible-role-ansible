.SILENT:
.PHONY: help

## Colors
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[33m

## Package
PACKAGE_VERSION = 1.9.4

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
	echo "deb-src http://ftp.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list
	echo "deb http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list
	apt-get update
	apt-get install -y dpkg-dev dh-python devscripts
	# Get package source
	mkdir -p ~/package && cd ~/package && apt-get source ansible
	# Build package
	apt-get build-dep -y ansible
	cd ~/package/ansible-${PACKAGE_VERSION} && debuild -us -uc
	# Move package files
	mkdir -p /srv/files/debian_wheezy
	rm -f /srv/files/debian_wheezy/ansible_*.deb
	mv ~/package/ansible_*.deb /srv/files/debian_wheezy
