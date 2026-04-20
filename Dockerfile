# syntax=docker/dockerfile:1.4

ARG BASE_IMAGE=ghcr.io/nvidia/openshell-community/sandboxes/base:latest
FROM ${BASE_IMAGE}

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    ffmpeg \
    ripgrep \
    vim-tiny \
    nano \
    ca-certificates \
    curl \
    git \
    unzip \
    gnupg \
    lsb-release \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
    && chmod go+r /etc/apt/keyrings/microsoft.gpg \
    && AZ_DIST=$(lsb_release -cs) \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${AZ_DIST} main" \
       > /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends azure-cli \
    && rm -rf /var/lib/apt/lists/*

# Node-based tools
RUN npm install -g mcporter

# Python-based tools
RUN /sandbox/.venv/bin/pip install --no-cache-dir openai-whisper

# Optional tools with source ambiguity:
# - goc
# - camsnap
# - nano-pdf
#
# Recommendation:
# COPY approved internal/static binaries into /usr/local/bin or install them in a
# later stage once the exact upstream source and versioning strategy are defined.

# Workspace paths
RUN mkdir -p /sandbox/shared /opt/company-data \
    && chown -R sandbox:sandbox /sandbox/shared /opt/company-data /sandbox

# Baseline policy active in the image
COPY policy/base-policy.yaml /etc/openshell/policy.yaml

USER sandbox
ENTRYPOINT ["/bin/bash"]
