#!/bin/sh
# Render /usr/share/nginx/html/sheasy-config.js from $SSHEASY_DECRYPT_KEY so
# the browser can decrypt the optional `epassword` URL parameter (AES-256-GCM).
# The official nginx image runs everything in /docker-entrypoint.d/*.sh before
# launching nginx, so this fires on every container start.
set -eu

OUT=/usr/share/nginx/html/sheasy-config.js
KEY="${SSHEASY_DECRYPT_KEY:-}"

if [ -z "$KEY" ]; then
  printf 'window.SSHEASY_KEY = null;\n' > "$OUT"
  echo "sheasy-config: no SSHEASY_DECRYPT_KEY set; epassword decryption disabled"
  exit 0
fi

# Basic sanity check: 32 bytes == 64 hex chars.
case "$KEY" in
  *[!0-9a-fA-F]*)
    echo "sheasy-config: SSHEASY_DECRYPT_KEY must be hex (got non-hex chars)" >&2
    exit 1
    ;;
esac
LEN=$(printf '%s' "$KEY" | wc -c | tr -d ' ')
if [ "$LEN" != "64" ]; then
  echo "sheasy-config: SSHEASY_DECRYPT_KEY must be 64 hex chars (32 bytes); got $LEN" >&2
  exit 1
fi

printf 'window.SSHEASY_KEY = "%s";\n' "$KEY" > "$OUT"
echo "sheasy-config: epassword decryption enabled"
