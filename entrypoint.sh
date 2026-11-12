#!/bin/sh
set -eu

# Derive N8N_HOST and N8N_WEBHOOK_URL from Render's RENDER_EXTERNAL_URL on first boot
# so a second deploy isn't needed to configure the public URL.
if [ -n "${RENDER_EXTERNAL_URL:-}" ]; then
  if [ -z "${N8N_HOST:-}" ]; then
    host="${RENDER_EXTERNAL_URL#https://}"
    host="${host#http://}"
    export N8N_HOST="${host%%/*}"
  fi

  # n8n 2.35+ replaced WEBHOOK_URL with N8N_WEBHOOK_URL; honor either if already set.
  if [ -z "${N8N_WEBHOOK_URL:-}" ] && [ -z "${WEBHOOK_URL:-}" ]; then
    export N8N_WEBHOOK_URL="${RENDER_EXTERNAL_URL%/}/"
  fi
fi

# Safe defaults when deployed as a plain Render Web Service (without Blueprint envVars).
# Any value already set in Render Environment or render.yaml takes precedence.
if [ -n "${DB_POSTGRESDB_HOST:-}" ]; then
  export DB_TYPE="${DB_TYPE:-postgresdb}"
  export DB_POSTGRESDB_PORT="${DB_POSTGRESDB_PORT:-5432}"
  export DB_POSTGRESDB_DATABASE="${DB_POSTGRESDB_DATABASE:-postgres}"
  export DB_POSTGRESDB_SCHEMA="${DB_POSTGRESDB_SCHEMA:-n8n}"
  export DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED="${DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED:-false}"
fi

export N8N_PORT="${N8N_PORT:-5678}"
export PORT="${PORT:-5678}"
export N8N_PROTOCOL="${N8N_PROTOCOL:-https}"
export GENERIC_TIMEZONE="${GENERIC_TIMEZONE:-Asia/Kolkata}"
export TZ="${TZ:-Asia/Kolkata}"
export N8N_DEFAULT_BINARY_DATA_MODE="${N8N_DEFAULT_BINARY_DATA_MODE:-filesystem}"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=256}"
export N8N_RUNNERS_MAX_OLD_SPACE_SIZE="${N8N_RUNNERS_MAX_OLD_SPACE_SIZE:-64}"
export EXECUTIONS_DATA_PRUNE="${EXECUTIONS_DATA_PRUNE:-true}"
export EXECUTIONS_DATA_MAX_AGE="${EXECUTIONS_DATA_MAX_AGE:-72}"
export N8N_DIAGNOSTICS_ENABLED="${N8N_DIAGNOSTICS_ENABLED:-false}"
export N8N_PERSONALIZATION_ENABLED="${N8N_PERSONALIZATION_ENABLED:-false}"

exec /docker-entrypoint.sh "$@"
