#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

HOSTNAME_VALUE=""
if [ -f .env ]; then
  HOSTNAME_VALUE="$(
    grep -E '^[[:space:]]*HOSTNAME[[:space:]]*=' .env | head -n 1 | cut -d '=' -f 2- | \
      sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"
  )"
fi

OLLAMA_LOCAL_URL="http://127.0.0.1:11434"
OLLAMA_TAGS_URL="${OLLAMA_LOCAL_URL}/api/tags"

printf '\n== Ollama health and tags endpoint ==\n'
if OLLAMA_JSON="$(curl -fsS --max-time 5 "${OLLAMA_TAGS_URL}")"; then
  printf 'OK: %s\n' "${OLLAMA_TAGS_URL}"
  if command -v jq >/dev/null 2>&1; then
    printf '%s\n' "${OLLAMA_JSON}" | jq -r '.models[]?.name' | sed 's/^/ - /' || true
  else
    printf '%s\n' "${OLLAMA_JSON}" | head -c 250
    printf '\n'
  fi
else
  printf 'FAIL: cannot reach %s\n' "${OLLAMA_TAGS_URL}"
fi

printf '\n== Docker Compose services ==\n'
docker compose ps || true

printf '\n== Open WebUI local endpoint ==\n'
LOCAL_HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:8080 || true)"
if [ "${LOCAL_HTTP_CODE}" = "000" ]; then
  printf 'FAIL: http://127.0.0.1:8080 is unreachable\n'
else
  printf 'HTTP %s: http://127.0.0.1:8080\n' "${LOCAL_HTTP_CODE}"
fi

if [ -n "${HOSTNAME_VALUE}" ]; then
  printf '\n== Remote hostname (optional check) ==\n'
  case "${HOSTNAME_VALUE}" in
    http://*|https://*) REMOTE_URL="${HOSTNAME_VALUE}" ;;
    *) REMOTE_URL="https://${HOSTNAME_VALUE}" ;;
  esac

  REMOTE_HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "${REMOTE_URL}" || true)"
  if [ "${REMOTE_HTTP_CODE}" = "000" ]; then
    printf 'UNREACHABLE: %s\n' "${REMOTE_URL}"
  else
    printf 'HTTP %s: %s\n' "${REMOTE_HTTP_CODE}" "${REMOTE_URL}"
    printf 'Note: Access-protected endpoints may return 302/401/403 until authenticated.\n'
  fi
fi
