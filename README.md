# OpenShell Custom Sandbox Package v5

This version updates the image to install OpenClaw from source via Git URL/ref.

## Main changes

- `Dockerfile` now installs OpenClaw with:
  `npm install -g "git+${OPENCLAW_GIT_URL}#${OPENCLAW_GIT_REF}"`
- npm global prefix is set to `/sandbox/.npm-global`
  so the sandbox user can update/reinstall OpenClaw later from source
- added preset:
  `policy/presets/openclaw-from-git.yaml`
- baked composed policy includes `openclaw_from_git`

## Build examples

Default:
```bash
docker build -t openshell-custom-openclaw-nvidia .
```

Custom repo/ref:
```bash
docker build \
  --build-arg OPENCLAW_GIT_URL=https://github.com/openclaw/openclaw.git \
  --build-arg OPENCLAW_GIT_REF=main \
  -t openshell-custom-openclaw-nvidia .
```

## Update OpenClaw later from inside the sandbox

Because `NPM_CONFIG_PREFIX=/sandbox/.npm-global`, you can reinstall without needing
writable `/usr/local`:

```bash
npm install -g "git+https://github.com/openclaw/openclaw.git#main"
```

## Create sandbox

```bash
openshell sandbox create --name my-openclaw-nvidia --from . --forward 18789 -- env CHAT_UI_URL=http://127.0.0.1:18789 openclaw-nvidia-start
```
