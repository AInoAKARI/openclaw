#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${OPENCLAW_ROOT_DIR:-$HOME/openclaw}"
GET_KEY="${GET_KEY_SCRIPT:-$HOME/keymaster/get_key.sh}"
KEYMASTER_ENV_FILE="${KEYMASTER_ENV_FILE:-$ROOT_DIR/.env}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $1" >&2
    exit 1
  }
}

load_env_file() {
  local env_file="$1"
  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

set_secret() {
  local env_name="$1"
  local service="$2"
  local field="${3:-api_key}"

  if [ -n "${!env_name:-}" ]; then
    echo "$env_name already set"
    return
  fi

  local value
  value="$("$GET_KEY" "$service" "$field")"
  export "$env_name=$value"
  echo "$env_name fetched from Keymaster"
}

require_cmd docker
require_cmd curl
require_cmd jq

if [ ! -x "$GET_KEY" ]; then
  echo "ERROR: key fetch script not found or not executable: $GET_KEY" >&2
  exit 1
fi

if [ ! -d "$ROOT_DIR" ]; then
  echo "ERROR: OpenClaw directory not found: $ROOT_DIR" >&2
  exit 1
fi

load_env_file "$KEYMASTER_ENV_FILE"

set_secret KIMI_API_KEY moonshot api_key_openclaw
set_secret OPENCLAW_GATEWAY_TOKEN openclaw gateway_token

if [ -n "${OPENCLAW_FETCH_TELEGRAM_TOKEN:-}" ]; then
  set_secret TELEGRAM_BOT_TOKEN telegram token
fi

cd "$ROOT_DIR"
docker compose up -d "$@"
docker compose ps
