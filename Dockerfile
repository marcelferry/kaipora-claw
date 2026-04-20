# syntax=docker/dockerfile:1.4

ARG BASE_IMAGE=ghcr.io/nvidia/openshell-community/sandboxes/base:latest
FROM ${BASE_IMAGE}

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Base packages requested for the custom sandbox.
RUN apt-get update && apt-get install -y --no-install-recommends     jq     ffmpeg     ripgrep     vim-tiny     nano     ca-certificates     curl     git     unzip     gnupg     lsb-release     build-essential     && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN mkdir -p /etc/apt/keyrings     && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg     && chmod go+r /etc/apt/keyrings/microsoft.gpg     && AZ_DIST=$(lsb_release -cs)     && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${AZ_DIST} main"        > /etc/apt/sources.list.d/azure-cli.list     && apt-get update     && apt-get install -y --no-install-recommends azure-cli     && rm -rf /var/lib/apt/lists/*

# gogcli (pinned release)
ARG GOGCLI_VERSION=0.12.0
RUN ARCH="$(dpkg --print-architecture)" &&     case "$ARCH" in       amd64) GOG_ARCH="x86_64" ;;       arm64) GOG_ARCH="arm64" ;;       *) echo "Unsupported arch: $ARCH" && exit 1 ;;     esac &&     curl -fsSL "https://github.com/steipete/gogcli/releases/download/v${GOGCLI_VERSION}/gogcli_${GOGCLI_VERSION}_linux_${GOG_ARCH}.tar.gz" -o /tmp/gogcli.tgz &&     tar -xzf /tmp/gogcli.tgz -C /tmp &&     install -m 0755 /tmp/gog /usr/local/bin/gog &&     rm -rf /tmp/gog /tmp/gogcli.tgz

# camsnap (pinned release)
ARG CAMSNAP_VERSION=0.2.0
RUN ARCH="$(dpkg --print-architecture)" &&     case "$ARCH" in       amd64) CAMSNAP_ARCH="x86_64" ;;       arm64) CAMSNAP_ARCH="arm64" ;;       *) echo "Unsupported arch: $ARCH" && exit 1 ;;     esac &&     curl -fsSL "https://github.com/steipete/camsnap/releases/download/v${CAMSNAP_VERSION}/camsnap_${CAMSNAP_VERSION}_linux_${CAMSNAP_ARCH}.tar.gz" -o /tmp/camsnap.tgz &&     tar -xzf /tmp/camsnap.tgz -C /tmp &&     install -m 0755 /tmp/camsnap /usr/local/bin/camsnap &&     rm -rf /tmp/camsnap /tmp/camsnap.tgz

# Node-based tools + OpenClaw, following the NVIDIA openclaw sandbox pattern.
ARG OPENCLAW_VERSION=2026.3.11
RUN npm install -g     mcporter     openclaw@${OPENCLAW_VERSION}

# Python-based tools
RUN /sandbox/.venv/bin/pip install --no-cache-dir     openai-whisper     "yt-dlp[default]"     nano-pdf

# OpenClaw helper following the NVIDIA community sandbox pattern.
COPY openclaw-start.sh /usr/local/bin/openclaw-start
RUN chmod +x /usr/local/bin/openclaw-start

# Workspace paths
RUN mkdir -p /sandbox/shared /opt/company-data /sandbox/.openclaw     && chown -R sandbox:sandbox /sandbox/shared /opt/company-data /sandbox/.openclaw /sandbox

# Baseline policy active in the image.
# Keep the custom baseline as the default; upstream OpenClaw-style rules are available as presets/compositions.
COPY policy/base-policy.yaml /etc/openshell/policy.yaml

USER sandbox
ENTRYPOINT ["/bin/bash"]
