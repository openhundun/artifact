FROM ghcr.io/openhundun/debian-python:13-3.14
COPY --from=ghcr.io/astral-sh/uv:0.12.8 /uv /usr/local/bin/uv
COPY --from=ghcr.io/astral-sh/uv:0.12.8 /uvx /usr/local/bin/uvx
ENV UV_DEFAULT_INDEX="https://mirrors.ustc.edu.cn/pypi/simple"
ENV UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone"
CMD ["uv", "--version"]
