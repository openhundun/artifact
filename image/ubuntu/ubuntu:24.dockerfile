FROM docker.io/library/ubuntu:24.04
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ARG TARGETARCH
ENV TIME_STYLE="+%Y-%m-%d %H:%M:%S"
ENV TZ="Asia/Shanghai"
RUN \
    MIRROR="$(case "${TARGETARCH}" in amd64) echo http://mirrors.ustc.edu.cn/ubuntu;; arm64) echo http://mirrors.ustc.edu.cn/ubuntu-ports;; *) exit 1;; esac)" && \
    tee /etc/apt/sources.list.d/ubuntu.sources > /dev/null <<EOF
Types: deb
URIs: ${MIRROR}
Suites: noble noble-updates noble-backports noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
RUN \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates curl file git iproute2 iputils-ping jq libstdc++6 lsof netcat-openbsd openssl procps tzdata unzip xz-utils zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists && \
    rm -rf /var/cache/apt/archives
