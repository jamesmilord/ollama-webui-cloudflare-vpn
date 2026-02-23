#!/usr/bin/env bash
set -euo pipefail

OLLAMA_LOCAL_URL="http://127.0.0.1:11434"
TAGS_ENDPOINT="${OLLAMA_LOCAL_URL}/api/tags"
LOG_DIR="${LOG_DIR:-./tmp}"
LOG_FILE="${LOG_DIR}/ollama-serve.log"
ERR_FILE="${LOG_DIR}/ollama-serve.err"

is_ollama_running() {
  curl -fsS --max-time 3 "${TAGS_ENDPOINT}" >/dev/null 2>&1
}

wait_for_ollama() {
  local attempts=0
  local max_attempts=30

  while [ "${attempts}" -lt "${max_attempts}" ]; do
    if is_ollama_running; then
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 1
  done

  return 1
}

if is_ollama_running; then
  echo "Ollama is already running at ${OLLAMA_LOCAL_URL}"
  exit 0
fi

echo "Ollama is not running. Attempting to start it..."

mkdir -p "${LOG_DIR}"
: > "${LOG_FILE}"
: > "${ERR_FILE}"

started=0

if command -v brew >/dev/null 2>&1; then
  if brew services start ollama >/dev/null 2>&1; then
    started=1
    echo "Started Ollama via Homebrew service"
  fi
fi

if [ "${started}" -eq 0 ]; then
  if command -v ollama >/dev/null 2>&1; then
    nohup ollama serve >>"${LOG_FILE}" 2>>"${ERR_FILE}" &
    started=1
    echo "Started Ollama via nohup ollama serve"
  fi
fi

if [ "${started}" -eq 0 ]; then
  echo "ERROR: Unable to start Ollama. Install Ollama and/or Homebrew first." >&2
  exit 1
fi

if wait_for_ollama; then
  echo "Ollama is healthy: ${TAGS_ENDPOINT}"
else
  echo "ERROR: Ollama did not become healthy in time." >&2
  echo "Check logs: ${LOG_FILE} and ${ERR_FILE}" >&2
  exit 1
fi
