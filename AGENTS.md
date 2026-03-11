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

## Repo-specific operating rules
- Treat `cloudflared/config.yml` as the template/source file.
- Treat `cloudflared/config.rendered.yml` as generated output.
- Do not hand-edit `cloudflared/config.rendered.yml`; it is rendered from `.env` by `scripts/up.sh`.
- Use the project entrypoints in `Makefile` when operating the stack:
  - `make up`
  - `make down`
  - `make status`
  - `make logs`

## Validation expectations
- After changing Docker, tunnel, startup, or environment behavior, validate with:
  - `make status`
  - `docker compose ps`
- If the change affects tunnel routing or remote access, also verify:
  - local Open WebUI at `http://127.0.0.1:8080`
  - Ollama tags API at `http://127.0.0.1:11434/api/tags`
- If a change cannot be validated locally, say so explicitly in the final handoff.

## Secrets and config hygiene
- Never commit or print secret values from `.env`.
- Never commit or print tunnel credential contents from `cloudflared/*.json`.
- Never commit generated runtime config that embeds deployment-specific values unless explicitly requested.
- When adding or renaming environment variables:
  - update `.env.example`
  - update any consuming code or Compose config
  - update `README.md` if setup or operations changed

## Network exposure policy
- Ollama must remain bound to local host usage only and must not be published through Docker or Cloudflare.
- `cloudflared` may only proxy to `open-webui:8080`.
- Preserve the current trust boundary where Cloudflare Access protects the internet-facing hostname before origin traffic reaches the local stack.

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

## Platform assumptions
- This repository is macOS-first.
- Ollama is expected to run on the host, not in Docker.
- The startup path may rely on:
  - Homebrew-managed `ollama` service, or
  - `ollama serve` started on the host
- Linux-specific networking changes should be treated as exceptions and documented in `README.md` when introduced.

## Change discipline
- Prefer minimal changes that preserve the existing architecture: host Ollama, containerized Open WebUI, containerized cloudflared.
- Do not add new internet-facing services or ingress rules without explicit approval.
