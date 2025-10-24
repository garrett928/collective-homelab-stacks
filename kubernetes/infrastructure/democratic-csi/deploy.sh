#!/bin/bash
set -e

# Democratic CSI Deployment Script
# This script deploys the democratic-csi driver for NFS storage from TrueNAS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="democratic-csi"
RELEASE_NAME="democratic-csi-nfs"
VALUES_FILE="$SCRIPT_DIR/democratic-csi-nfs-secret.yaml"

echo "===================================="
echo "Democratic CSI Deployment Script"
echo "===================================="
echo ""

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo "❌ Error: Values file not found: $VALUES_FILE"
    echo "Please create the democratic-csi-nfs-secret.yaml file first."
    exit 1
fi

echo "✅ Found values file: $VALUES_FILE"
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed"
    echo "Please install helm first: https://helm.sh/docs/intro/install/"
    exit 1
fi

echo "✅ Helm is installed: $(helm version --short)"
echo ""

# Add democratic-csi helm repo if not already added
echo "📦 Adding/updating democratic-csi helm repository..."
helm repo add democratic-csi https://democratic-csi.github.io/charts/ 2>/dev/null || true
helm repo update democratic-csi
echo ""

# Check if release already exists
if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
    echo "🔄 Upgrading existing release..."
    ACTION="upgrade"
else
    echo "🚀 Installing new release..."
    ACTION="install"
fi

# Deploy/upgrade the helm chart
echo ""
echo "Deploying democratic-csi..."
helm upgrade --install \
    --values "$VALUES_FILE" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    "$RELEASE_NAME" \
    democratic-csi/democratic-csi

echo ""
echo "===================================="
echo "✅ Deployment complete!"
echo "===================================="
echo ""
echo "Verify deployment with:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl get storageclass truenas-nfs"
echo "  kubectl get csidriver org.democratic-csi.nfs"
echo ""
echo "View logs with:"
echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/component=controller -c csi-driver"
echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/component=node -c csi-driver"
echo ""
