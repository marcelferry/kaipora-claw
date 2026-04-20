# OpenShell Custom Sandbox Package

Pacote base para criar uma sandbox customizada no estilo OpenShell/OpenShell-Community, com ferramentas pré-instaladas e políticas organizadas por presets.

## O que este pacote entrega

- `Dockerfile` baseado em `ghcr.io/nvidia/openshell-community/sandboxes/base:latest`
- baseline policy em `policy/base-policy.yaml`
- presets de rede em `policy/presets/`
- composições prontas em `policy/composed/`
- script para compor políticas: `scripts/compose_policy.py`

## Ferramentas já incluídas no Dockerfile

Instaladas automaticamente:
- nano
- vim / vi
- jq
- ffmpeg
- ripgrep
- azure-cli
- mcporter
- openai-whisper

Pendentes de origem/versionamento explícito:
- goc
- camsnap
- nano-pdf

Esses três ficaram intencionalmente fora da instalação automática para evitar um build frágil enquanto a origem oficial e o método de distribuição não estiverem fechados.

## Estrutura de policies

### Baseline
`policy/base-policy.yaml`

Mantém:
- filesystem controlado
- processo rodando como `sandbox`
- sem egress liberado por padrão (`network_policies: {}`)

### Presets
Arquivos em `policy/presets/`:
- `npm.yaml`
- `pypi.yaml`
- `azure.yaml`
- `azure-devops.yaml`
- `microsoft-identity.yaml`
- `google-apis.yaml`
- `github.yaml`

### Policies compostas já prontas
Arquivos em `policy/composed/`:
- `balanced.yaml`
- `enterprise-azure.yaml`
- `full-dev.yaml`

## Como compor uma policy nova

Instale a dependência do script:

```bash
python3 -m pip install -r scripts/requirements.txt
```

Monte uma policy combinando presets:

```bash
python3 scripts/compose_policy.py   --base policy/base-policy.yaml   --preset-dir policy/presets   --presets npm pypi azure azure-devops microsoft-identity   --output policy/composed/my-enterprise.yaml
```

## Como usar a policy composta

### 1. Embutir na imagem
No Dockerfile, já está apontando para:

```dockerfile
COPY policy/base-policy.yaml /etc/openshell/policy.yaml
```

Se quiser usar outra por padrão, troque para algo como:

```dockerfile
COPY policy/composed/enterprise-azure.yaml /etc/openshell/policy.yaml
```

### 2. Aplicar depois via OpenShell
Você também pode subir a sandbox com a baseline e depois aplicar uma policy composta com o fluxo de `policy set`, conforme seu padrão operacional.

## Build da imagem

```bash
docker build -t my-openshell-sandbox .
```

## Próximos ajustes recomendados

1. Fixar versão exata do `BASE_IMAGE`
2. Fixar versão do `mcporter`
3. Definir origem oficial para:
   - goc
   - camsnap
   - nano-pdf
4. Criar presets adicionais se fizer sentido:
   - huggingface
   - gemini
   - artifact registries
   - docker registries
