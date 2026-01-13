Chart App Framework for HPE Private Cloud AI
Overview
This Helm chart deploys a simple Flask application on HPE Private Cloud AI (PCAI). The app runs in a containerized environment, exposed via Kubernetes service and optionally Istio VirtualService for external access. This application is capable of deleting, adding, and viewing details of existing charts. It is also possible to filter by date.
Default credentials for access: Username - chartadmin, Password - chartpassword.
Adaptations for PCAI

Helm Chart: Configured with defaults for PCAI, including resource limits in values.yaml (editable for CPU/memory/GPU). Supports Istio integration via ezua.virtualService for gateway routing.
Docker Image: Built from Dockerfile (not provided here; assume standard Flask setup). Image: liavna/chart-app:latest.
Networking: Service exposes port 80 (maps to app's 5000). VirtualService enables external endpoint like chart.${DOMAIN_NAME} through Istio gateway.
Minimal Changes: Standard Kubernetes resources used; no major PCAI-specific mods beyond Istio for secure exposure.

For suggestions or requests, please contact Liav Nachmani at liav@hpe.com.