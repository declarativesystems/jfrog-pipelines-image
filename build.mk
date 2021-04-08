ifeq ($(shell uname -s), Linux)
	CONTAINER_CMD=podman
	CONTAINER_BUILD_CMD=buildah bud --format docker
else
	CONTAINER_CMD=docker
	CONTAINER_BUILD_CMD=docker build
endif

git_rev := $(shell git rev-parse --short HEAD)
# remove leading 'v'
# the currently checked out tag or nothing
git_tag := $(shell git tag --points-at HEAD 2> /dev/null | cut -c 2- | grep -E '.+')

ifdef git_tag
	# on a release tag
	final_version = $(git_tag)
	container_version = $(git_tag)
	python_version = $(git_tag)
else
	# snapshot build
	final_version = $(base_version)-$(git_rev)
	container_version = $(base_version)-$(git_rev)
	python_version = $(base_version)+$(git_rev)
endif

print_version:
	@echo $(final_version)

print_version_python:
	@echo $(python_version)

ci_image_push:
	$(CONTAINER_CMD) push $(ci_image_name):$(container_version)

print_docker_image_id:
	@echo $(ci_image_name):$(container_version)

ci_shell:
	@echo "project files will be available at /mnt"
	$(CONTAINER_CMD) run --rm -v $(shell pwd):/mnt -ti \
		$(shell yq e '.pipelines.[0].configuration.runtime.image.custom.name' pipelines.yml):$(shell yq e '.pipelines.[0].configuration.runtime.image.custom.tag' pipelines.yml) \
		/bin/bash

shell:
	podman run --entrypoint /bin/bash -ti $(ci_image_name):$(container_version)
