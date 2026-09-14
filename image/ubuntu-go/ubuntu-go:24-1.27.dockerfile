FROM ghcr.io/openhundun/ubuntu:24
COPY --from=docker.io/library/golang:1.27 /usr/local/go /opt/go
ENV GOROOT="/opt/go"
ENV GOPROXY="https://goproxy.cn,direct"
ENV GOTOOLCHAIN="local"
ENV CGO_ENABLED="0"
ENV PATH="/opt/go/bin:${PATH}"
CMD ["go", "version"]
