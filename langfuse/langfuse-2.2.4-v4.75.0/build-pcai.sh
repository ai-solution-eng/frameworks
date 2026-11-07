#!/usr/bin/env bash
# ================================================================
# Build langfuse-<chartver>-v<appver>.tgz for PCAI
#
# WHY THIS SCRIPT EXISTS
#   The bundled SeaweedFS sub-chart calls Helm's fromToml function.
#   PCAI's Helm is too old to know it, and Helm parses EVERY template in an
#   enabled sub-chart - even ones whose conditions are false. So the install
#   fails before rendering anything:
#
#       Error: parse error at (langfuse/charts/s3/templates/shared/
#              security-configmap.yaml:21): function "fromToml" not defined
#
#   global.seaweedfs.enableSecurity defaults to false, so that template block
#   never actually executes. We only need it to PARSE, so the call is swapped
#   for dict(). Behaviour is unchanged.
#
# RE-RUN THIS whenever the SeaweedFS sub-chart version changes.
# ================================================================
set -euo pipefail

CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$CHART_DIR/.." && pwd)"
cd "$CHART_DIR"

echo "==> helm dependency build"
helm dependency build .

SW_TGZ="$(ls charts/seaweedfs-*.tgz 2>/dev/null | head -1)"
if [ -z "$SW_TGZ" ]; then
  echo "ERROR: no seaweedfs chart found in charts/" >&2
  exit 1
fi

echo "==> patching $SW_TGZ"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

tar xzf "$SW_TGZ" -C "$WORK"
F="$WORK/seaweedfs/templates/shared/security-configmap.yaml"

if grep -q ':= fromToml' "$F"; then
  python3 - "$F" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = '{{- $securityConfig := fromToml (dig "data" "security.toml" "" $existing) }}'
new = ('{{- /* PATCHED for PCAI: fromToml needs a newer Helm than the platform ships.\n'
       '       global.seaweedfs.enableSecurity defaults to false, so this block\n'
       '       never executes; dict() keeps the template parseable. */}}\n'
       '  {{- $securityConfig := dict }}')
n = s.count(old)
if n != 1:
    sys.exit("ERROR: expected 1 fromToml call, found %d" % n)
open(p, "w").write(s.replace(old, new))
PY
  ( cd "$WORK" && tar czf "$CHART_DIR/$SW_TGZ" seaweedfs )
  echo "    patched"
else
  echo "    nothing to patch (already patched, or chart changed - verify!)"
fi

echo "==> helm package"
OUT="$(mktemp -d)"
helm package . -d "$OUT" >/dev/null
BUILT="$(ls "$OUT"/*.tgz | head -1)"

CV="$(grep -E '^version:' Chart.yaml | awk '{print $2}' | tr -d '"')"
AV="$(grep -E '^appVersion:' Chart.yaml | awk '{print $2}' | tr -d '"')"
FINAL="$REPO_ROOT/langfuse-${CV}-v${AV}.tgz"
mv "$BUILT" "$FINAL"

echo
echo "==> package: $FINAL"
echo "==> chart $CV / app $AV"
echo "==> bundled sub-charts:"
tar tzf "$FINAL" | grep '^[^/]*/charts/' | cut -d/ -f3 | sort -u | sed 's/^/    /'

echo
echo "==> verifying the fromToml call is gone"
INNER="$(tar tzf "$FINAL" | grep "charts/$SW_TGZ" | head -1)"
tar xzOf "$FINAL" "$INNER" > "$WORK/check.tgz"
if tar xzOf "$WORK/check.tgz" seaweedfs/templates/shared/security-configmap.yaml | grep -q ':= fromToml'; then
  echo "    FAILED - unpatched fromToml still present" >&2
  exit 1
fi
echo "    OK - no fromToml call"
