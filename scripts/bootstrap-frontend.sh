#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
PNPM_VERSION="10.24.0"

usage() {
  echo "Usage: $0 [--clean]"
}

if [[ "${1:-}" != "" && "${1:-}" != "--clean" ]]; then
  usage
  exit 2
fi

cd "$FRONTEND_DIR"

corepack prepare "pnpm@$PNPM_VERSION" --activate

if [[ "${1:-}" == "--clean" ]]; then
  rm -rf node_modules .svelte-kit
fi

corepack pnpm install --frozen-lockfile
corepack pnpm run check
corepack pnpm run build
