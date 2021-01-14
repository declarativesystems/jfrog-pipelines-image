# Ubuntu 20.10
FROM ubuntu:groovy-20201125.2
ARG DEBIAN_FRONTEND=noninteractive

# https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst
ARG AWS_CLI_VERSION="2.1.18"

# https://github.com/jfrog/jfrog-cli/blob/master/RELEASE.md
ARG JFROG_CLI_VERSION="1.43.2"

# https://nodejs.org/en/
ARG NODE_JS_VERSION="v15.5.1"

# https://golang.org/dl/
ARG GOLANG_VERSION="1.15.6"

# https://github.com/goreleaser/goreleaser/
ARG GORELEASER_VERSION="v0.154.0"

# https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
ARG AWS_KUBECTL_VERSION="1.18.9/2020-11-02"

# https://www.npmjs.com/package/ajv-cli
ARG AVG_CLI_VERSION="4.0.1"

# https://www.npmjs.com/package/js-beautify
ARG JS_BEAUTIFY_VERSION="1.13.4"

# https://www.npmjs.com/package/yarn
ARG YARN_VERSION="1.22.10"

ENV PATH=/usr/local/node/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

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
RUN pip install pipenv wheel

# GCP - not supported
# Azure - not supported
# helm - todo
# terraform - not supported
# packer - not supported
# ansible - not supported


# AWS API
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# JFrog CLI
RUN wget -nv https://api.bintray.com/content/jfrog/jfrog-cli-go/${JFROG_CLI_VERSION}/jfrog-cli-linux-amd64/jfrog?bt_package=jfrog-cli-linux-amd64 -O jfrog \
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
RUN sed -i 's/driver = ""/driver = "vfs"/' /etc/containers/storage.conf

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

RUN apt clean && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
