#!/usr/bin/env bash

set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$SCRIPT_DIR" || exit 1

# Remove, re-package, and re-deploy ezapp

### MAKE SURE CORRECT KUBECONFIG IS SELECTED!

# Delete the ezapp deployment
kubectl delete -f webollama-ezapp.yaml || true

# Get version from Chart.yaml
VERSION=$(grep '^version:' ./chart/Chart.yaml | awk '{print $2}')
echo "Processing version: $VERSION"

# Package the chart
helm package ./chart

# Forward chartmuseum port for localhost
kubectl port-forward -n ez-chartmuseum-ns svc/chartmuseum 8080:8080 &

sleep 3

# Delete the old chart (if it exists)
curl -X DELETE http://localhost:8080/api/charts/webollama/$VERSION || true

# Upload the new chart
curl -X POST http://localhost:8080/api/charts --data-binary "@webollama-$VERSION.tgz"

# Install the ezapp
kubectl apply -f webollama-ezapp.yaml

# Kill the port-forward
kill %1

echo "Redeployed"