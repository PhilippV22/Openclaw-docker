# OpenClaw Docker Setup

Dieses Repository baut ein lauffaehiges OpenClaw Docker-Image und startet es per Docker Compose.

Standardmaessig wird OpenClaw aus dem offiziellen Repository gebaut:
- Repo: `https://github.com/openclaw/openclaw.git`
- Ref: `v2026.2.9` (Release vom 09.02.2026)

## Voraussetzungen

- Docker Engine oder Docker Desktop
- Docker Compose v2 (`docker compose version`)

## Schnellstart

```bash
chmod +x docker-setup.sh
./docker-setup.sh
```

Das Skript macht automatisch:
- Image bauen
- Gateway-Token erzeugen (falls nicht gesetzt)
- Onboarding starten
- Gateway starten

Danach ist OpenClaw in der Regel unter `http://127.0.0.1:18789/` erreichbar.

## Wichtige Umgebungsvariablen

- `OPENCLAW_REPO`: Quelle fuer OpenClaw
- `OPENCLAW_REF`: Branch/Tag/Commit zum Bauen
- `OPENCLAW_CONTAINER_UID`: UID des Users im Container (Default `1000`)
- `OPENCLAW_CONTAINER_GID`: GID des Users im Container (Default `1000`)
- `OPENCLAW_IMAGE`: Lokaler Image-Name
- `OPENCLAW_DOCKER_APT_PACKAGES`: zusaetzliche apt-Pakete beim Build
- `OPENCLAW_CONFIG_DIR`: Host-Pfad fuer `~/.openclaw`
- `OPENCLAW_WORKSPACE_DIR`: Host-Pfad fuer Workspace
- `OPENCLAW_GATEWAY_PORT`: Host-Port fuer Gateway (Default `18789`)
- `OPENCLAW_BRIDGE_PORT`: Host-Port fuer Bridge (Default `18790`)
- `OPENCLAW_GATEWAY_BIND`: `lan` oder `loopback`
- `OPENCLAW_EXTRA_MOUNTS`: optionale zusaetzliche Bind-Mounts
- `OPENCLAW_HOME_VOLUME`: optionales Docker Volume fuer `/home/node`

## Manuell ohne Setup-Skript

```bash
docker build \
  --build-arg OPENCLAW_REPO=https://github.com/openclaw/openclaw.git \
  --build-arg OPENCLAW_REF=v2026.2.9 \
  -t openclaw:local \
  .

docker compose run --rm openclaw-cli onboard --no-install-daemon
docker compose up -d openclaw-gateway
```

## Nuetzliche Befehle

```bash
docker compose logs -f openclaw-gateway
docker compose run --rm openclaw-cli dashboard --no-open
docker compose exec openclaw-gateway node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
```

## Troubleshooting

Wenn beim Onboarding `EACCES: permission denied, open '/home/node/.openclaw/.env'` kommt,
passen Host-Rechte und Container-UID nicht zusammen.

Typischer Fix (wenn du als root arbeitest):

```bash
chown -R 1000:1000 /root/.openclaw
```

Alternativ UID/GID in `.env` passend setzen:

```bash
OPENCLAW_CONTAINER_UID=1000
OPENCLAW_CONTAINER_GID=1000
```

Wenn `docker-setup.sh` nach dem Onboarding nicht bis `==> Starting gateway` kommt,
starte den Gateway manuell:

```bash
docker compose up -d openclaw-gateway
docker compose logs -f openclaw-gateway
```

Wenn `unauthorized: gateway token mismatch` kommt:

```bash
source .env
docker compose exec openclaw-gateway \
  node -e "const fs=require('node:fs');const JSON5=require('json5');const c=JSON5.parse(fs.readFileSync('/home/node/.openclaw/openclaw.json','utf8'));console.log(c?.gateway?.auth?.token||'')"
```

Den ausgegebenen Token in `.env` als `OPENCLAW_GATEWAY_TOKEN` setzen und Gateway neu starten:

```bash
docker compose up -d --force-recreate openclaw-gateway
```

Fuer Cloudflare Tunnel muss der Ingress auf den lokalen Gateway zeigen:

```yaml
ingress:
  - hostname: claw.example.com
    service: http://127.0.0.1:18789
  - service: http_status:404
```
