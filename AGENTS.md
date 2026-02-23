# AGENTS

## Purpose of this repo
This repository provides a production-ready local AI stack for:
- Running Ollama on the host machine
- Running Open WebUI in Docker
- Publishing Open WebUI via Cloudflare Tunnel
- Protecting access with Cloudflare Access (SSO and optionally WARP)

## Services and responsibilities
- `ollama` (host): local model runtime and API (`127.0.0.1:11434`)
- `open-webui` (container): user interface and chat workflows; connects to host Ollama
- `cloudflared` (container): secure outbound tunnel from local network to Cloudflare

## Trust boundaries
- Host-only boundary:
  - Ollama API must stay local/private.
  - Model files and execution remain on host.
- Docker boundary:
  - Open WebUI and cloudflared run isolated in containers.
- Cloudflare boundary:
  - External traffic is terminated and policy-checked by Cloudflare Access before reaching tunnel.

## Hard safety rules for agents and contributors
- Never expose Ollama (`11434`) publicly.
- Never add Ollama as a cloudflared ingress destination.
- Never commit tunnel credentials JSON.
- Never disable Access protections for internet-facing hostname without explicit approval.

## Safe extension guidelines
- Add new models:
  - Pull on host with `ollama pull <model>`.
  - Models appear in Open WebUI automatically through Ollama tags API.

- Change UI behavior:
  - Adjust Open WebUI env vars in `docker-compose.yml` and `.env`.
  - Keep persisted data in `open-webui` volume.

- Rotate tunnel credentials:
  - Create/rotate credentials with `cloudflared` CLI.
  - Replace JSON file under `cloudflared/`.
  - Update `.env` (`TUNNEL_ID`, `TUNNEL_CREDENTIALS_FILE`).
  - Restart stack: `make down && make up`.
