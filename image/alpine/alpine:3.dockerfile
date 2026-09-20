FROM docker.io/library/alpine:3
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ENV TIME_STYLE="+%Y-%m-%d %H:%M:%S"
ENV TZ="Asia/Shanghai"
RUN \
    sed -i 's|dl-cdn.alpinelinux.org|mirrors.ustc.edu.cn|g' /etc/apk/repositories && \
    apk add --no-cache ca-certificates curl file git iproute2 iputils jq libstdc++ lsof netcat-openbsd openssl procps-ng tzdata unzip xz zip
