FROM ghcr.io/openhundun/ubuntu:24
ARG TARGETARCH
ARG PYTHON_URL_AMD64="https://registry.npmmirror.com/-/binary/python-build-standalone/20260825/cpython-3.14.7+20260825-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz"
ARG PYTHON_URL_ARM64="https://registry.npmmirror.com/-/binary/python-build-standalone/20260825/cpython-3.14.7+20260825-aarch64-unknown-linux-gnu-install_only_stripped.tar.gz"
ENV PIP_DISABLE_PIP_VERSION_CHECK="1"
ENV PIP_INDEX_URL="https://mirrors.ustc.edu.cn/pypi/simple"
ENV PYTHONDONTWRITEBYTECODE="1"
ENV PYTHONFAULTHANDLER="1"
ENV PATH="/opt/python/bin:${PATH}"
RUN \
    PYTHON_URL="$(case "${TARGETARCH}" in amd64) echo "${PYTHON_URL_AMD64}";; arm64) echo "${PYTHON_URL_ARM64}";; *) exit 1;; esac)" && \
    mkdir -p /opt/python && \
    curl -fsSL -o /tmp/python.tar.gz "${PYTHON_URL}" && \
    tar -C /opt/python --strip-components 1 --no-same-owner -xzf /tmp/python.tar.gz && \
    rm -rf /tmp/python.tar.gz
CMD ["python3", "--version"]
