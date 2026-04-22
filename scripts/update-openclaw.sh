#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${1:-${OPENCLAW_GIT_URL:-https://github.com/openclaw/openclaw.git}}"
REPO_REF="${2:-${OPENCLAW_GIT_REF:-main}}"

OPENCLAW_SRC_DIR="${OPENCLAW_SRC_DIR:-/sandbox/src/openclaw}"
OPENCLAW_INSTALL_BIN_DIR="${OPENCLAW_INSTALL_BIN_DIR:-/sandbox/.npm-global/bin}"
OPENCLAW_INSTALL_LINK="${OPENCLAW_INSTALL_LINK:-${OPENCLAW_INSTALL_BIN_DIR}/openclaw}"

log() {
  printf '[update-openclaw] %s\n' "$*"
}

fail() {
  printf '[update-openclaw] ERROR: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Comando não encontrado: $1"
}

ensure_bun() {
  if command -v bun >/dev/null 2>&1; then
    log "bun já disponível em: $(command -v bun)"
    return
  fi

  log "bun não encontrado; instalando em /sandbox/.bun"
  export BUN_INSTALL="/sandbox/.bun"
  mkdir -p "$BUN_INSTALL"
  curl -fsSL https://bun.sh/install | bash
  export PATH="$BUN_INSTALL/bin:$PATH"

  command -v bun >/dev/null 2>&1 || fail "Falha ao instalar bun"
}

prepare_paths() {
  mkdir -p "$(dirname "$OPENCLAW_SRC_DIR")"
  mkdir -p "$OPENCLAW_INSTALL_BIN_DIR"

  export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-/sandbox/.npm-global}"
  export PATH="${OPENCLAW_INSTALL_BIN_DIR}:$PATH"
}

sync_repo() {
  if [[ -d "$OPENCLAW_SRC_DIR/.git" ]]; then
    log "Repositório já existe; atualizando em $OPENCLAW_SRC_DIR"
    git -C "$OPENCLAW_SRC_DIR" remote set-url origin "$REPO_URL"
    git -C "$OPENCLAW_SRC_DIR" fetch --tags --prune origin
  else
    log "Clonando $REPO_URL em $OPENCLAW_SRC_DIR"
    git clone "$REPO_URL" "$OPENCLAW_SRC_DIR"
  fi

  log "Fazendo checkout de $REPO_REF"
  git -C "$OPENCLAW_SRC_DIR" checkout "$REPO_REF"

  if git -C "$OPENCLAW_SRC_DIR" rev-parse --verify "origin/$REPO_REF" >/dev/null 2>&1; then
    git -C "$OPENCLAW_SRC_DIR" reset --hard "origin/$REPO_REF"
  fi

  log "Commit atual: $(git -C "$OPENCLAW_SRC_DIR" rev-parse --short HEAD)"
}

build_openclaw() {
  cd "$OPENCLAW_SRC_DIR"

  log "Habilitando corepack"
  corepack enable

  ensure_bun

  log "Instalando dependências"
  pnpm install

  log "Executando build:docker"
  pnpm build:docker

  log "Executando ui:build"
  pnpm ui:build

  log "Executando qa:lab:build"
  pnpm qa:lab:build
}

install_launcher() {
  cd "$OPENCLAW_SRC_DIR"

  [[ -f "openclaw.mjs" ]] || fail "Arquivo openclaw.mjs não encontrado após build"

  log "Publicando launcher em $OPENCLAW_INSTALL_LINK"
  ln -sf "$OPENCLAW_SRC_DIR/openclaw.mjs" "$OPENCLAW_INSTALL_LINK"
  chmod +x "$OPENCLAW_SRC_DIR/openclaw.mjs"

  log "Validação final"
  "$OPENCLAW_INSTALL_LINK" --help >/dev/null 2>&1 || true

  log "OpenClaw atualizado com sucesso"
  log "Launcher: $OPENCLAW_INSTALL_LINK"
  log "Repo: $REPO_URL"
  log "Ref: $REPO_REF"
  log "Commit: $(git -C "$OPENCLAW_SRC_DIR" rev-parse --short HEAD)"
}

main() {
  require_cmd git
  require_cmd curl
  require_cmd node
  require_cmd corepack

  prepare_paths
  sync_repo
  build_openclaw
  install_launcher
}

main "$@"
