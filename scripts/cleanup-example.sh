#!/bin/bash
# =============================================================================
# Cleanup Hello World Example
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NAMESPACE="hello-world"
CLUSTER_NAME="imeks-testbed"
REGION="ap-northeast-2"

echo "=============================================="
echo "  IMEKS Hello World Example - Cleanup"
echo "=============================================="

# Ensure kubectl is configured
echo ""
echo "[1/4] Configuring kubectl..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" 2>/dev/null || true
echo "  ✓ kubectl configured"

# Check if namespace exists
echo ""
echo "[2/4] Checking resources..."
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo "  Found namespace: $NAMESPACE"

    # Show current resources
    echo ""
    echo "  Current resources in $NAMESPACE:"
    kubectl get all -n "$NAMESPACE" 2>/dev/null || true
    kubectl get ingress -n "$NAMESPACE" 2>/dev/null || true

    # Delete RBAC resources (cluster-scoped)
    echo ""
    echo "[3/4] Deleting RBAC resources..."
    kubectl delete -f "$PROJECT_ROOT/examples/rbac/" --ignore-not-found
    echo "  ✓ RBAC resources deleted"

    # Delete namespace (this will delete all resources within it)
    echo ""
    echo "[4/4] Deleting namespace and all resources..."
    kubectl delete namespace "$NAMESPACE" --timeout=120s
    echo "  ✓ Namespace deleted"

    # Wait for ALB to be cleaned up
    echo ""
    echo "  Waiting for ALB cleanup (30 seconds)..."
    sleep 30
    echo "  ✓ Cleanup complete"
else
    echo "  Namespace '$NAMESPACE' not found. Nothing to clean up."
fi

echo ""
echo "=============================================="
echo "  Cleanup Summary"
echo "=============================================="
echo ""
echo "  Deleted resources:"
echo "  - RBAC: developer-role, viewer-role"
echo "  - Namespace: $NAMESPACE"
echo "    - Deployment: hello-world"
echo "    - Service: hello-world"
echo "    - Ingress: hello-world (ALB)"
echo ""
echo "  Note: ALB may take a few minutes to be fully removed from AWS."
echo ""
