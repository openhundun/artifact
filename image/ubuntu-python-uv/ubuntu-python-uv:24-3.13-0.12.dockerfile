ARG IMAGE_REGISTRY="ghcr.io"

FROM ${IMAGE_REGISTRY}/openhundun/ubuntu-python:24-3.13
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
COPY --from=ghcr.io/astral-sh/uv:0.12.18 /uv /usr/local/bin/uv
COPY --from=ghcr.io/astral-sh/uv:0.12.18 /uvx /usr/local/bin/uvx
ENV UV_DEFAULT_INDEX="https://mirrors.cernet.edu.cn/pypi/simple"
ENV UV_PYTHON_INSTALL_MIRROR="https://mirrors.cernet.edu.cn/python-build-standalone"
