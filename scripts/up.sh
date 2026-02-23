#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

read_env_var() {
  local key="$1"
  local raw

  raw="$(
    grep -E "^[[:space:]]*${key}[[:space:]]*=" .env | head -n 1 | cut -d '=' -f 2- || true
  )"

  raw="$(printf '%s' "${raw}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  raw="$(printf '%s' "${raw}" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
  printf '%s' "${raw}"
}

HOSTNAME_VALUE=""
if [ -f .env ]; then
  HOSTNAME_VALUE="$(read_env_var HOSTNAME)"
  TUNNEL_ID_VALUE="$(read_env_var TUNNEL_ID)"
  TUNNEL_CREDENTIALS_FILE_VALUE="$(read_env_var TUNNEL_CREDENTIALS_FILE)"
else
  echo "ERROR: .env file not found. Create it from .env.example first." >&2
  exit 1
fi

if [ -z "${TUNNEL_ID_VALUE:-}" ] || [ -z "${TUNNEL_CREDENTIALS_FILE_VALUE:-}" ] || [ -z "${HOSTNAME_VALUE}" ]; then
  echo "ERROR: .env must define HOSTNAME, TUNNEL_ID, and TUNNEL_CREDENTIALS_FILE." >&2
  exit 1
fi

if [ ! -f "cloudflared/${TUNNEL_CREDENTIALS_FILE_VALUE}" ]; then
  echo "ERROR: missing tunnel credentials file: cloudflared/${TUNNEL_CREDENTIALS_FILE_VALUE}" >&2
  exit 1
fi

cat > "${ROOT_DIR}/cloudflared/config.rendered.yml" <<EOF
tunnel: ${TUNNEL_ID_VALUE}
credentials-file: /etc/cloudflared/${TUNNEL_CREDENTIALS_FILE_VALUE}
ingress:
  - hostname: ${HOSTNAME_VALUE}
    service: http://open-webui:8080
  - service: http_status:404
EOF

"${ROOT_DIR}/scripts/ensure-ollama.sh"

docker compose up -d

LOCAL_URL="http://localhost:8080"
REMOTE_URL=""

if [ -n "${HOSTNAME_VALUE}" ]; then
  case "${HOSTNAME_VALUE}" in
    http://*|https://*) REMOTE_URL="${HOSTNAME_VALUE}" ;;
    *) REMOTE_URL="https://${HOSTNAME_VALUE}" ;;
  esac
fi

echo
echo "Open WebUI local URL: ${LOCAL_URL}"
if [ -n "${REMOTE_URL}" ]; then
  echo "Open WebUI remote URL: ${REMOTE_URL}"
else
  echo "Open WebUI remote URL: set HOSTNAME in .env"
fi
