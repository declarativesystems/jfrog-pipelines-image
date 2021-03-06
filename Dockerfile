# Ubuntu 20.10
FROM ubuntu:groovy-20201125.2
ARG DEBIAN_FRONTEND=noninteractive

# https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst
ARG AWS_CLI_VERSION="2.1.35"

# https://github.com/jfrog/jfrog-cli/blob/master/RELEASE.md
ARG JFROG_CLI_VERSION="1.46.1"

# https://nodejs.org/en/
ARG NODE_JS_VERSION="v15.14.0"

# https://golang.org/dl/
ARG GOLANG_VERSION="1.16.3"

# https://github.com/goreleaser/goreleaser/releases
ARG GORELEASER_VERSION="v0.162.0"

# https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
ARG AWS_KUBECTL_VERSION="1.19.6/2021-01-05"

# https://www.npmjs.com/package/ajv-cli
ARG AVG_CLI_VERSION="4.0.1"

# https://www.npmjs.com/package/js-beautify
ARG JS_BEAUTIFY_VERSION="1.13.5"

# https://www.npmjs.com/package/yarn
ARG YARN_VERSION="1.22.10"

# https://github.com/weaveworks/eksctl/releases
ARG EKSCTL_VERSION="0.44.0"

# https://github.com/helm/helm/releases
ARG HELM_VERSION="v3.5.3"

# /usr/lib/cri-o-runc/sbin runc must be in PATH or there will be mid-build
# errors from buildah
ENV PATH=/usr/local/node/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/cri-o-runc/sbin

WORKDIR /tmp/downloads

RUN apt update && apt install -y \
    sudo \
    software-properties-common \
    wget \
    unzip \
    curl \
    openssh-client \
    ftp \
    gettext \
    smbclient \
    mercurial \
    make \
    tree \
    jq \
    git \
    bash \
    pip \
    python-is-python3\
    gawk \
    vim

# Python (system for now - 3.8)
RUN pip install pipenv wheel poetry

# GCP - not supported
# Azure - not supported
# terraform - not supported
# packer - not supported
# ansible - not supported


# AWS API
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
    && unzip -q awscliv2.zip \
    && ./aws/install

# JFrog CLI
RUN curl -LO https://releases.jfrog.io/artifactory/jfrog-cli/v1/${JFROG_CLI_VERSION}/jfrog-cli-linux-amd64/jfrog \
    && chmod +x jfrog \
    && mv jfrog /usr/bin/jfrog

# NodeJS
RUN curl -O https://nodejs.org/dist/${NODE_JS_VERSION}/node-${NODE_JS_VERSION}-linux-x64.tar.xz \
    && tar -Jxf node-${NODE_JS_VERSION}-linux-x64.tar.xz \
    && mv node-${NODE_JS_VERSION}-linux-x64 /usr/local \
    && ln -s /usr/local/node-${NODE_JS_VERSION}-linux-x64 /usr/local/node

# Golang
RUN curl -LO https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz \
    && tar -zxf go${GOLANG_VERSION}.linux-amd64.tar.gz \
    && mv go go${GOLANG_VERSION} \
    && mv go${GOLANG_VERSION} /usr/local \
    && ln -s /usr/local/go${GOLANG_VERSION} /usr/local/go

# podman is in ubuntu 20.10 but has a bug where dockerfile in subdir of context
# is not allowed, so use the suse packages instead. force the 20.04 files since
# there is no 20.10 build
RUN echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
    && curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key | sudo apt-key add - \
    && apt update \
    && apt -y install podman

# buildah
RUN apt install -y buildah

# force vfs driver to allow running in pipelines containerised build
RUN sed -i 's/driver = "[^"]*"/driver = "vfs"/' /etc/containers/storage.conf

# run setup script in your builds to store images outside the container (vital)
COPY container_storage_setup /usr/local/bin
RUN chmod +x /usr/local/bin/container_storage_setup

# goreleaser
RUN curl -LO https://github.com/goreleaser/goreleaser/releases/download/${GORELEASER_VERSION}/goreleaser_amd64.deb \
    && dpkg -i goreleaser_amd64.deb

# kubectl - AWS
RUN curl -o /usr/local/bin/kubectl \
    https://amazon-eks.s3.us-west-2.amazonaws.com/${AWS_KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl

# JSON schema validator
RUN npm install -g ajv-cli@${AVG_CLI_VERSION}

# js-beautify
RUN npm install -g js-beautify@${JS_BEAUTIFY_VERSION}

# yarn
RUN npm install -g yarn@${YARN_VERSION}

# eksctl
RUN curl -LO https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz \
    && tar -zxf eksctl_Linux_amd64.tar.gz \
    && mv eksctl /usr/local/bin

# helm
RUN curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -zxf  helm-${HELM_VERSION}-linux-amd64.tar.gz\
    && mv linux-amd64/helm /usr/local/bin

RUN apt clean && rm -rf /var/lib/apt/lists/* /tmp/downloads

CMD ["/bin/bash"]
