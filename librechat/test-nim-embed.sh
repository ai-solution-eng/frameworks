#!/usr/bin/env bash
# Probe the NIM embeddings endpoint directly to find the accepted input_type.
# Usage: ./test-nim-embed.sh
set -euo pipefail

NIM_BASE="https://nv-embedqa-e5-v5-1.project-user-daniel-cao.serving.dc15-0104-ai-application.pcai0104.dc15.hpecolo.net/v1"

POD="nim-test-$$"
kubectl -n librechat run "$POD" --image=curlimages/curl --restart=Never >/dev/null
trap 'kubectl -n librechat delete pod "$POD" --force --grace-period=0 >/dev/null 2>&1' EXIT
kubectl -n librechat wait --for=condition=Ready pod/"$POD" --timeout=60s

run() { kubectl -n librechat exec "$POD" -- curl -sk --max-time 15 "$@"; }

echo "--- 1) models endpoint ---"
run "$NIM_BASE/models" | head -c 300; echo

for IT in query passage text; do
  echo "--- 2) input_type=$IT (input as string) ---"
  run -X POST "$NIM_BASE/embeddings" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"nv-embedqa-e5-v5\",\"input\":\"hello\",\"input_type\":\"$IT\"}" | head -c 200; echo
done

echo "--- 3) input as list, input_type=query ---"
run -X POST "$NIM_BASE/embeddings" \
  -H "Content-Type: application/json" \
  -d '{"model":"nv-embedqa-e5-v5","input":["hello"],"input_type":"query"}' | head -c 200; echo
