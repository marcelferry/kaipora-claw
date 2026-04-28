# syntax=docker/dockerfile:1.4

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# OpenClaw sandbox image for OpenShell
#
# Builds on the community base sandbox and adds OpenClaw.
# Build:  docker build -t openshell-openclaw --build-arg BASE_IMAGE=openshell-base .
# Run:    openshell sandbox create --from openclaw

ARG BASE_IMAGE=ghcr.io/nvidia/openshell-community/sandboxes/base:latest
FROM ${BASE_IMAGE}

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Base tools requested by user
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

# npm / Python tools requested by user
RUN npm install -g mcporter

RUN /sandbox/.venv/bin/pip install --no-cache-dir \
    openai-whisper \
    "yt-dlp[default]" \
    nano-pdf

# npm global prefix inside /sandbox so the sandbox user can reinstall/update tools later
RUN mkdir -p /sandbox/.npm-global/bin \
    && chown -R sandbox:sandbox /sandbox/.npm-global

ENV NPM_CONFIG_PREFIX=/sandbox/.npm-global
ENV PATH=/sandbox/.npm-global/bin:${PATH}

# OpenClaw from source (build from cloned repo instead of npm git install)
ARG OPENCLAW_GIT_URL=https://github.com/marcelferry/openclaw.git
ARG OPENCLAW_GIT_REF=main

RUN rm -rf /app/openclaw \
    && git clone --depth 1 --branch "${OPENCLAW_GIT_REF}" "${OPENCLAW_GIT_URL}" /app/openclaw \
    && cd /app/openclaw \
    && corepack enable \
    && curl -fsSL https://bun.sh/install | bash \
    && export PATH="/root/.bun/bin:${PATH}" \
    && pnpm install \
    && pnpm build:docker \
    && pnpm ui:build \
    && pnpm qa:lab:build \
    && chmod +x /app/openclaw/openclaw.mjs \
    && chown -R sandbox:sandbox /app/openclaw

ARG GOGCLI_VERSION=0.12.0
RUN ARCH="$(dpkg --print-architecture)" && \
    case "$ARCH" in \
      amd64) GOG_ARCH="x86_64" ;; \
      arm64) GOG_ARCH="arm64" ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/steipete/gogcli/releases/download/v${GOGCLI_VERSION}/gogcli_${GOGCLI_VERSION}_linux_${GOG_ARCH}.tar.gz" -o /tmp/gogcli.tgz && \
    tar -xzf /tmp/gogcli.tgz -C /tmp && \
    install -m 0755 /tmp/gog /usr/local/bin/gog && \
    rm -rf /tmp/gog /tmp/gogcli.tgz

ARG CAMSNAP_VERSION=0.2.0
RUN ARCH="$(dpkg --print-architecture)" && \
    case "$ARCH" in \
      amd64) CAM_ARCH="x86_64" ;; \
      arm64) CAM_ARCH="arm64" ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/steipete/camsnap/releases/download/v${CAMSNAP_VERSION}/camsnap_${CAMSNAP_VERSION}_linux_${CAM_ARCH}.tar.gz" -o /tmp/camsnap.tgz && \
    tar -xzf /tmp/camsnap.tgz -C /tmp && \
    install -m 0755 /tmp/camsnap /usr/local/bin/camsnap && \
    rm -rf /tmp/camsnap /tmp/camsnap.tgz

RUN mkdir -p /etc/openshell
COPY policy/composed/enterprise-azure-openclaw-nvidia.yaml /etc/openshell/policy.yaml
COPY scripts/openclaw-nvidia-start.sh /usr/local/bin/openclaw-nvidia-start
COPY scripts/update-openclaw.sh /usr/local/bin/update-openclaw
COPY scripts/node-openclaw-os-shim.cjs /usr/local/lib/node-openclaw-os-shim.cjs
RUN chmod +x /usr/local/bin/openclaw-nvidia-start /usr/local/bin/update-openclaw \
    && chmod 644 /usr/local/lib/node-openclaw-os-shim.cjs \
    && printf '%s\n' \
      '#!/usr/bin/env bash' \
      'exec node --require /usr/local/lib/node-openclaw-os-shim.cjs /app/openclaw/openclaw.mjs "$@"' \
      > /usr/local/bin/openclaw \
    && chmod +x /usr/local/bin/openclaw \
    && printf '%s\n' \
      '#!/usr/bin/env bash' \
      'exec /usr/local/bin/openclaw "$@"' \
      > /sandbox/.npm-global/bin/openclaw \
    && chmod +x /sandbox/.npm-global/bin/openclaw

RUN npm install -g @grpc/grpc-js @grpc/proto-loader js-yaml
RUN npm install -g @hono/node-server@1.19.11

RUN mkdir -p /sandbox/.local/bin /usr/local/bin \
    && ln -sf /usr/local/bin/gog /sandbox/.local/bin/gog \
    && ln -sf /usr/bin/node /usr/local/bin/node \
    && (ln -sf /usr/bin/npm /usr/local/bin/npm || true) \
    && (ln -sf /usr/bin/npx /usr/local/bin/npx || true)

RUN grep -q '/sandbox/.npm-global/bin' /sandbox/.bashrc || \
    printf '\nexport PATH="/sandbox/.npm-global/bin:$PATH"\n' >> /sandbox/.bashrc \
    && grep -q '/sandbox/.npm-global/bin' /sandbox/.profile || \
    printf '\nexport PATH="/sandbox/.npm-global/bin:$PATH"\n' >> /sandbox/.profile \
    && chown sandbox:sandbox /sandbox/.bashrc /sandbox/.profile

RUN mkdir -p /sandbox/.openclaw /sandbox/shared /opt/company-data /sandbox/bin /sandbox/src \
    && ln -sf /usr/local/bin/update-openclaw /sandbox/bin/update-openclaw.sh \
    && chown -R sandbox:sandbox /sandbox/.openclaw /sandbox/shared /opt/company-data /etc/openshell /sandbox

USER sandbox
ENTRYPOINT ["/bin/bash"]