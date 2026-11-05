#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/environment/docker-compose.yml"

echo "[*] Arresto e rimozione dei container del laboratorio"
docker compose -f "$COMPOSE_FILE" down -v || true

echo "[*] Rimozione dell'immagine applicativa"
docker image rm ops-dashboard:lab 2>/dev/null || true

echo "[*] Rimozione della prova di escape dall'host"
rm -f /tmp/ESCAPE_PROOF.txt 2>/dev/null || true

echo "[+] Cleanup completato"
