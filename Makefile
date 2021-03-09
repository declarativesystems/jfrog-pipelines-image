git_rev := $(shell git rev-parse --short HEAD)
# remove leading 'v'
# the currently checked out tag or 0.0.0=
git_tag := $(shell git describe --tags 2> /dev/null | cut -c 2- | grep -E '.+')
base_version := "0.8.0"

ifdef git_tag
	# on a release tag
	final_version = $(git_tag)
else
	# snapshot build
	final_version = $(base_version)-$(git_rev)
endif

image_name := declarativesystems.jfrog.io/docker-local/pipelines

image:
	buildah bud \
		-f Dockerfile \
		--squash \
		-t $(image_name):$(final_version)

push:
	podman push $(image_name):$(final_version)

shell:
	podman run --rm -v $(shell pwd):/mnt -ti $(image_name):$(final_version) /bin/bash

print_image_name:
	@echo $(image_name)

print_image_tag:
	@echo $(final_version)


