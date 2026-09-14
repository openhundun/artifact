FROM ghcr.io/openhundun/ubuntu:24
COPY --from=docker.io/library/golang:1.27 /usr/local/go /opt/go
ENV CGO_ENABLED="0"
ENV GOPROXY="https://goproxy.cn,direct"
ENV GOROOT="/opt/go"
ENV GOTOOLCHAIN="local"
ENV PATH="/opt/go/bin:${PATH}"
CMD ["go", "version"]
