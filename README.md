# OpenShell Custom Sandbox Package v4

This package is explicitly aligned to `NVIDIA/OpenShell-Community/sandboxes/openclaw-nvidia`
instead of `sandboxes/openclaw`.

## What changed in this version

- Base image now follows the upstream `openclaw-nvidia` direction:
  `ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest`
- Keeps the upstream startup pattern via `openclaw-nvidia-start`
- Preserves user-requested customizations where they overlap:
  custom tools, Python/npm CLIs, and policy presets
- Uses a composed policy as the baked default:
  `policy/composed/enterprise-azure-openclaw-nvidia.yaml`

## Upstream references used

- `sandboxes/openclaw-nvidia/README.md`
- `sandboxes/openclaw-nvidia/Dockerfile`
- `sandboxes/openclaw-nvidia/policy.yaml`
- `sandboxes/openclaw-nvidia/openclaw-nvidia-start.sh`

## Included custom tools

- nano
- vim / vi
- jq
- ffmpeg
- ripgrep
- azure-cli
- mcporter
- openai-whisper
- yt-dlp
- nano-pdf
- gog
- camsnap

## Policy layout

- `policy/base-policy.yaml`
- `policy/presets/*.yaml`
- `policy/composed/balanced.yaml`
- `policy/composed/enterprise-azure.yaml`
- `policy/composed/enterprise-azure-openclaw-nvidia.yaml`

The baked image default is:
- `policy/composed/enterprise-azure-openclaw-nvidia.yaml`

This is intentional: it keeps your requested Azure/Python/Node presets while also
bringing in the key `openclaw-nvidia`-style network allowances.

## Build

```bash
docker build -t openshell-custom-openclaw-nvidia .
```

## Create sandbox

```bash
openshell sandbox create --name my-openclaw-nvidia --from . --forward 18789 -- env CHAT_UI_URL=http://127.0.0.1:18789 openclaw-nvidia-start
```

## Notes

- This package does **not** add the NeMoClaw DevX UI extension bundle from the upstream
  source tree. It aligns to the `openclaw-nvidia` container/runtime model and startup flow,
  but stays focused on your requested custom image and policy composition.
- If you want full parity with the UI extension pieces (`policy-proxy.js`,
  `inference-options.js`, extension bundle injection), that can be added in a next version.
