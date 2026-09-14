FROM docker.io/library/alpine:3
ENV TZ="Asia/Shanghai"
ENV TIME_STYLE="+%Y-%m-%d %H:%M:%S"
RUN \
    sed -i 's|dl-cdn.alpinelinux.org|mirrors.ustc.edu.cn|g' /etc/apk/repositories && \
    apk add --no-cache ca-certificates curl file git iproute2 iputils jq libstdc++ lsof netcat-openbsd openssl procps-ng tzdata unzip xz zip
