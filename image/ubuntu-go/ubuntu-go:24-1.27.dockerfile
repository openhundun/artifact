ARG IMAGE_REGISTRY="ghcr.io"

FROM ${IMAGE_REGISTRY}/openhundun/ubuntu:24
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
COPY --from=docker.io/library/golang:1.27 /usr/local/go /opt/go
ENV CGO_ENABLED="0"
ENV GO111MODULE="on"
ENV GOPROXY="https://goproxy.cn,direct"
ENV GOROOT="/opt/go"
ENV GOTOOLCHAIN="local"
ENV PATH="/opt/go/bin:${PATH}"
