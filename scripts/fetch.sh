#!/usr/bin/env bash
# Fetch a URL as Markdown via proxy cascade with auto-fallback.
# Usage: fetch.sh <url> [proxy_url]
# Example: fetch.sh https://example.com http://127.0.0.1:7890
set -euo pipefail

URL="${1:?Usage: fetch.sh <url> [proxy_url]}"
PROXY="${2:-}"

_curl() {
  if [ -n "$PROXY" ]; then
    https_proxy="$PROXY" http_proxy="$PROXY" curl -sL "$@"
  else
    curl -sL "$@"
  fi
}

_has_content() {
  local content="$1"
  local line_count=$(printf '%s\n' "$content" | wc -l | tr -d ' ')

  # Must have more than 5 lines
  [ "$line_count" -gt 5 ] || return 1

  # Filter out common error pages (grep -c counts matching lines;
  # if ALL lines match an error pattern the content is an error page)
  local total_lines="$line_count"
  local match
  for pattern in "Don't miss what's happening" "Access Denied" "404 Not Found"; do
    match=$(printf '%s\n' "$content" | grep -c "$pattern" || true)
    [ "$match" -lt "$total_lines" ] || return 1
  done

  return 0
}

# 1. r.jina.ai - wide coverage, preserves image links
OUT=$(_curl "https://r.jina.ai/$URL" 2>/dev/null || true)
if _has_content "$OUT"; then
  echo "$OUT"
  exit 0
fi

# 2. defuddle.md - cleaner output with YAML frontmatter
OUT=$(_curl "https://defuddle.md/$URL" 2>/dev/null || true)
if _has_content "$OUT"; then
  echo "$OUT"
  exit 0
fi

# 3. agent-fetch - last resort local tool
if command -v npx &>/dev/null; then
  OUT=$(npx --yes agent-fetch "$URL" --json 2>/dev/null || true)
  if [ -n "$OUT" ]; then
    echo "$OUT"
    exit 0
  fi
fi

echo "ERROR: All fetch methods failed for: $URL" >&2
exit 1
