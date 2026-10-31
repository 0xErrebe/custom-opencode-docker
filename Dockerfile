# Extends the official opencode sandbox image with an install/compile toolchain.
# Base: Alpine Linux 3.24, root user, ENTRYPOINT ["opencode"].
ARG OPENCODE_VERSION=2.2.0
FROM ghcr.io/anomalyco/opencode:${OPENCODE_VERSION}

RUN apk add --no-cache \
        git \
        nodejs \
        npm \
        python3 \
        python3-dev \
        py3-pip \
        go \
        build-base \
        bash \
        curl \
        openssh-client

# Windows bind mounts (/workdir, config, data) trigger git "dubious ownership".
RUN git config --system --add safe.directory '*'

# Alpine marks Python externally-managed (PEP 668). The container is ephemeral
# and root, so allow plain `pip install` (venv still works too).
ENV PIP_BREAK_SYSTEM_PACKAGES=1
