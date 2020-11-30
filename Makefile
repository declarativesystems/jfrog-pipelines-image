IMAGE_TAG := 0.0.2
IMAGE_NAME := declarativesystems.jfrog.io/docker/docker-local/pipelines
IMAGE_VERSION := $(IMAGE_NAME):$(IMAGE_TAG)


image:
	podman build . -t $(IMAGE_VERSION)

shell:
	podman run --rm -v $(shell pwd):/mnt -ti $(IMAGE_VERSION) /bin/bash

print_image_name:
	@echo $(IMAGE_NAME)

print_image_tag:
	@echo $(IMAGE_TAG)
