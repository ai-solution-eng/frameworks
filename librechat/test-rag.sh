#!/usr/bin/env bash
# Lean smoke test for the LibreChat RAG API from inside the cluster.
# Usage: ./test-rag.sh [namespace] [release-prefix]
#   default: ns=librechat  release=librechat
set -euo pipefail

NS="${1:-librechat}"
REL="${2:-librechat}"
RAG_SVC="${REL}-rag:${RAG_PORT:-8000}"

# One-off curl pod in the same namespace (deleted at exit)
POD="rag-test-$$"
kubectl -n "$NS" run "$POD" --image=curlimages/curl --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"c","image":"curlimages/curl","command":["sleep","300"],"stdin":true}]}}'
trap 'kubectl -n "$NS" delete pod "$POD" --force --grace-period=0 >/dev/null 2>&1' EXIT
kubectl -n "$NS" wait --for=condition=Ready pod/"$POD" --timeout=60s

run() { kubectl -n "$NS" exec "$POD" -- curl -s --max-time 20 "$@"; }
echo "--- 1) health ---"
run "http://${RAG_SVC}/health" && echo

echo "--- 0) available routes (openapi) ---"
run "http://${RAG_SVC}/openapi.json" | tr ',' '\n' | grep -o '"/[a-z0-9_/-]*"' | sort -u || true

echo "--- 2) embed-upload sample doc (multipart file_id + file) ---"
cat <<'EOF' > /tmp/rag-test.txt
Anywhere Airlines Refund Policy.
Passengers who are involuntarily downgraded on flights longer than 250 km
are entitled to a refund of 50% of the fare difference.
EOF
kubectl -n "$NS" cp /tmp/rag-test.txt "$POD":/tmp/doc.txt
run -X POST "http://${RAG_SVC}/embed-upload" -F "file_id=smoke-test-doc" -F "uploaded_file=@/tmp/doc.txt" && echo

echo "--- 3) query (requires file_id in this build) ---"
run -X POST "http://${RAG_SVC}/query" \
  -H "Content-Type: application/json" \
  -d '{"query":"How much can I get refunded for an involuntary downgrade?","file_id":"smoke-test-doc","k":3}' && echo
