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

exec /docker-entrypoint.sh "$@"
