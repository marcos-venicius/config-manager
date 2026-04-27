FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ARG GO_VERSION=1.22.2

RUN apt-get update

RUN apt-get install -y sudo

RUN useradd -m dev

RUN usermod -aG sudo dev

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER dev

# Create the workspace directory
WORKDIR /home/dev/app

RUN sudo apt-get install -y \
    curl \
    ca-certificates \
    && curl -OL https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

# Set Environment Variables
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# Verify installation
RUN go version

CMD ["/bin/bash"]
