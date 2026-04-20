# OpenShell Custom Sandbox Package v3

Pacote evoluído para manter a customização pedida e, ao mesmo tempo, suportar o padrão de instalação do sandbox `openclaw` da NVIDIA.

## O que mudou nesta versão

Além da base customizada anterior, esta versão incorpora o modelo do sandbox `openclaw` da NVIDIA:

- instala `openclaw` via npm global
- adiciona o helper `openclaw-start`
- prepara o diretório `/sandbox/.openclaw`
- mantém a baseline policy customizada como padrão da imagem
- adiciona um preset `openclaw-upstream.yaml` com regras inspiradas no sandbox upstream
- adiciona uma composição pronta `openclaw-enterprise-azure.yaml`

## Regra de precedência aplicada

Quando houve sobreposição entre o modelo NVIDIA e as suas escolhas:

- ferramentas customizadas foram preservadas
- a baseline policy customizada continuou como policy padrão da imagem
- as regras OpenClaw upstream entraram como preset/composição adicional, não como override automático

## Ferramentas incluídas no Dockerfile

- nano
- vim / vi
- jq
- ffmpeg
- ripgrep
- azure-cli
- gog
- camsnap
- mcporter
- openai-whisper
- yt-dlp
- nano-pdf
- openclaw

## Arquivos principais

- `Dockerfile`
- `openclaw-start.sh`
- `policy/base-policy.yaml`
- `policy/presets/openclaw-upstream.yaml`
- `policy/composed/openclaw-enterprise-azure.yaml`

## Como subir no estilo OpenClaw da NVIDIA

### Criar a sandbox

```bash
docker build -t my-openshell-openclaw-sandbox .
```

Depois, com OpenShell:

```bash
openshell sandbox create --from ./ --forward 18789 -- openclaw-start
```

O helper `openclaw-start` executa:

1. `openclaw onboard`
2. `openclaw gateway run` em background
3. imprime a URL local da UI

## Policies

### Padrão da imagem

A imagem continua embutindo por padrão:

```dockerfile
COPY policy/base-policy.yaml /etc/openshell/policy.yaml
```

### Preset inspirado no upstream

O preset `policy/presets/openclaw-upstream.yaml` traz regras alinhadas ao sandbox `openclaw` da NVIDIA para:

- `claude_code`
- `nvidia`
- `nvidia_web`
- `github_rest_api`

### Composição pronta

`policy/composed/openclaw-enterprise-azure.yaml` junta:

- baseline customizada
- npm
- pypi
- azure
- azure-devops
- microsoft-identity
- github
- regras OpenClaw upstream

## Observações

- A baseline continua deny-by-default para rede quando usada sozinha.
- Os presets/composições permitem abrir acesso de forma intencional.
- As versões de `gog`, `camsnap` e `openclaw` estão pinadas no Dockerfile para deixar o build mais reprodutível.
