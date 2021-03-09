git_rev := $(shell git rev-parse --short HEAD)
# remove leading 'v'
# the currently checked out tag or nothing
git_tag := $(shell git tag --points-at HEAD 2> /dev/null | cut -c 2- | grep -E '.+')
base_version := "0.8.0"

ifdef git_tag
	# on a release tag
	final_version = $(git_tag)
else
	# snapshot build
	final_version = $(base_version)-$(git_rev)
endif

image_name := declarativesystems.jfrog.io/docker-local/pipelines
image_tag := $(image_name):$(final_version)

image:
	buildah bud \
		--format docker \
		-f Dockerfile \
		--squash \
		-t $(image_tag)

push:
	podman push $(image_tag)

shell:
	podman run --rm -v $(shell pwd):/mnt -ti $(image_tag) /bin/bash

print_image_name:
	@echo $(image_name)

print_image_tag:
	@echo $(image_tag)


