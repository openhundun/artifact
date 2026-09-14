FROM docker.io/library/debian:13-slim
ENV TZ="Asia/Shanghai"
ENV TIME_STYLE="+%Y-%m-%d %H:%M:%S"
RUN tee /etc/apt/sources.list.d/debian.sources > /dev/null <<EOF
Types: deb
URIs: http://mirrors.ustc.edu.cn/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://mirrors.ustc.edu.cn/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
RUN \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates curl file git iproute2 iputils-ping jq libstdc++6 lsof netcat-openbsd openssl procps tzdata unzip xz-utils zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists && \
    rm -rf /var/cache/apt/archives
