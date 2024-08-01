FROM golang:1.22 AS builder
ARG TARGETOS
ARG TARGETARCH
ARG GOPATH
ARG GOPROXY

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.sum ./
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN --mount=type=cache,target=${HOME}/.cache/go-build \
    --mount=type=cache,target=${GOPATH}/pkg/mod \
    go mod download

# Copy the go source
COPY . .

ARG CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH}

# Build
# the GOARCH has not a default value to allow the binary be built according to the host where the command
# was called. For example, if we call make docker-build in a local env which has the Apple Silicon M1 SO
# the docker BUILDPLATFORM arg will be linux/arm64 when for Apple x86 it will be linux/amd64. Therefore,
# by leaving it empty we can ensure that the container and binary shipped on it will have the same platform.
RUN --mount=type=cache,target=${HOME}/.cache/go-build \
    --mount=type=cache,target=${GOPATH}/pkg/mod \
    mkdir build && \
    cd cmd && go build -v -a -o ../build/celestia-server

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM ubuntu:22.04
WORKDIR /

COPY --from=builder /workspace/build/* /usr/bin/

ENTRYPOINT ["./usr/bin/celestia-server"]