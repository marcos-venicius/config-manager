# Use Ubuntu as base image
FROM ubuntu:22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget tar ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set Go version
ENV GO_VERSION=1.22.5

# Download and install Go
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

# Set Go environment variables
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"

# Create workspace
RUN mkdir -p $GOPATH/src $GOPATH/bin
WORKDIR $GOPATH

# Default command
CMD ["go", "version"]
