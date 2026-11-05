#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/environment/docker-compose.yml"

echo "[*] Costruzione e avvio dell'ambiente di laboratorio"
docker compose -f "$COMPOSE_FILE" up -d --build

echo "[*] Attesa che il servizio sia pronto"
for i in $(seq 1 30); do
  if curl -fsS "http://localhost:8080/health" >/dev/null 2>&1; then
    echo "[+] Dashboard raggiungibile su http://localhost:8080"
    exit 0
  fi
  sleep 1
done

echo "[!] Il servizio non e' diventato raggiungibile entro il tempo previsto"
docker compose -f "$COMPOSE_FILE" ps
exit 1
