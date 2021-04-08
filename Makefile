base_version := "0.9.0"
ci_image_name := declarativesystems.jfrog.io/docker-local/pipelines


image_build:
	buildah bud --format docker --squash -t $(ci_image_name):$(final_version)

image_push:
	podman push $(image_tag)


include build.mk

