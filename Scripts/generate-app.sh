#!/usr/bin/env bash
# Gera AppPoker.xcodeproj a partir de project.yml (requer xcodegen no Mac).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen não encontrado. Instale com: brew install xcodegen" >&2
  echo "Ou abra Package.swift no Xcode e adicione manualmente os fontes de App/AppPoker/." >&2
  exit 1
fi

xcodegen generate
echo "Pronto: abra AppPoker.xcodeproj"
