# Ollama + Open WebUI + Cloudflare Tunnel (macOS-first)

## 1) Architecture overview
- `ollama` runs on the macOS host at `127.0.0.1:11434`.
- `open-webui` runs in Docker and connects to host Ollama via `OLLAMA_BASE_URL`.
- `cloudflared` runs in Docker and forwards `https://ai.<your-domain>` to `open-webui:8080`.
- Only Open WebUI is exposed through Cloudflare Tunnel. Ollama is never exposed publicly.

## 2) Prerequisites
- macOS with [Homebrew](https://brew.sh/)
- [Ollama](https://ollama.com/download)
- Docker Desktop (or Docker Engine + Compose plugin)
- Cloudflare account with a managed domain
- `cloudflared` CLI installed locally for tunnel bootstrap

Install core tools on macOS:
```bash
brew install cloudflared
brew install --cask docker
```

## 3) Quick start
1. Copy environment template:
```bash
cp .env.example .env
```

2. Edit `.env` values:
- `DOMAIN`
- `HOSTNAME` (for example `ai.example.com`)
- `TUNNEL_ID`
- `TUNNEL_CREDENTIALS_FILE`

3. Ensure scripts are executable:
```bash
chmod +x scripts/*.sh
```

4. Start everything with one command:
```bash
make up
```
`make up` renders `cloudflared/config.rendered.yml` from `.env` before starting containers.

5. Check status:
```bash
make status
```

## 4) Cloudflare Tunnel creation commands
Run these on your local machine (outside containers):

```bash
cloudflared tunnel login
cloudflared tunnel create ollama-webui
```

Capture the generated tunnel ID and credentials JSON filename from `~/.cloudflared/`.

Copy credentials into this repo:
```bash
cp ~/.cloudflared/<TUNNEL_ID>.json ./cloudflared/
```

Set `.env`:
- `TUNNEL_ID=<TUNNEL_ID>`
- `TUNNEL_CREDENTIALS_FILE=<TUNNEL_ID>.json`

## 5) DNS routing
Create DNS route for your hostname:
```bash
cloudflared tunnel route dns ollama-webui ai.example.com
```

Set `.env` with `HOSTNAME=ai.example.com`.

`cloudflared/config.yml` routes traffic to `http://open-webui:8080` and falls back to HTTP 404 for unmatched ingress.

## 6) Cloudflare Access policies (WARP vs SSO)
Create an Access application for `https://ai.example.com`:
- App type: Self-hosted
- Domain: `ai.example.com`

Policy option A (SSO-only):
- Include: your IdP users/groups (Google, GitHub, Okta, etc.)
- Require: valid identity login

Policy option B (WARP-required, VPN-like):
- Include: your IdP users/groups
- Require: `Gateway -> WARP` posture/connection rule
- Result: only devices connected through Cloudflare WARP can access

You can combine both: require SSO identity and WARP device state.

## 7) Troubleshooting
- Ollama not starting:
  - Verify `ollama` exists: `which ollama`
  - Try manual run: `ollama serve`
  - Inspect logs: `tmp/ollama-serve.log`, `tmp/ollama-serve.err`

- Open WebUI cannot reach Ollama:
  - Confirm host service: `curl http://127.0.0.1:11434/api/tags`
  - Confirm container env: `OLLAMA_BASE_URL=http://host.docker.internal:11434`

- Cloudflare tunnel down:
  - `docker compose logs -f cloudflared`
  - Check rendered config: `cloudflared/config.rendered.yml`
  - Check credentials file exists at `cloudflared/<TUNNEL_ID>.json`

- Remote URL prompts for Access:
  - Expected when Access policy is enabled
  - Authenticate or connect WARP based on policy

## 8) Security notes
- Never expose Ollama (`11434`) to the internet.
- Keep tunnel credentials JSON private; it is gitignored by default.
- Prefer Access policies with least privilege.
- Rotate tunnel credentials if leaked.

## Linux note
On Linux, `host.docker.internal` may require setup. Alternative:
- Use Docker host gateway mapping or
- Set `OLLAMA_BASE_URL` to a reachable host IP (for example `http://172.17.0.1:11434`).
