#!/bin/bash
# =============================================================================
# Deploy and Test Hello World Example
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NAMESPACE="hello-world"
CLUSTER_NAME="imeks-testbed"
REGION="ap-northeast-2"

echo "=============================================="
echo "  IMEKS Hello World Example - Deploy & Test"
echo "=============================================="

# Step 1: Configure kubectl
echo ""
echo "[1/6] Configuring kubectl..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo "  ✓ kubectl configured"

# Step 2: Verify cluster connection
echo ""
echo "[2/6] Verifying cluster connection..."
kubectl cluster-info
echo "  ✓ Cluster connection verified"

# Step 3: Deploy RBAC resources
echo ""
echo "[3/6] Deploying RBAC resources..."
kubectl apply -f "$PROJECT_ROOT/examples/rbac/"
echo "  ✓ RBAC resources applied"

# Show RBAC status
echo ""
echo "  RBAC Resources:"
kubectl get roles,rolebindings -A 2>/dev/null | grep -E "(developer|viewer)" || true
kubectl get clusterroles,clusterrolebindings 2>/dev/null | grep -E "(developer|viewer)" || true

# Step 4: Deploy hello-world example
echo ""
echo "[4/6] Deploying hello-world example..."
kubectl apply -f "$PROJECT_ROOT/examples/hello-world/"
echo "  ✓ Resources applied"

# Step 5: Wait for pods to be ready
echo ""
echo "[5/6] Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods -l app=hello-world -n "$NAMESPACE" --timeout=120s
echo "  ✓ Pods are ready"

# Show pod status
echo ""
echo "  Pod Status:"
kubectl get pods -n "$NAMESPACE" -o wide

# Step 6: Wait for ALB to be provisioned
echo ""
echo "[6/6] Waiting for ALB to be provisioned (this may take 2-3 minutes)..."
echo "  Checking Ingress status..."

MAX_RETRIES=30
RETRY_INTERVAL=10
for i in $(seq 1 $MAX_RETRIES); do
    ALB_ADDRESS=$(kubectl get ingress hello-world -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

    if [ -n "$ALB_ADDRESS" ]; then
        echo "  ✓ ALB provisioned: $ALB_ADDRESS"
        break
    fi

    if [ $i -eq $MAX_RETRIES ]; then
        echo "  ✗ Timeout waiting for ALB"
        echo ""
        echo "  Ingress Status:"
        kubectl describe ingress hello-world -n "$NAMESPACE"
        exit 1
    fi

    echo "  Waiting... ($i/$MAX_RETRIES)"
    sleep $RETRY_INTERVAL
done

# Wait a bit more for ALB to be fully ready
echo ""
echo "  Waiting for ALB to be fully ready (30 seconds)..."
sleep 30

# Test HTTP endpoint
echo ""
echo "=============================================="
echo "  Testing HTTP Endpoint"
echo "=============================================="
echo ""
echo "  URL: http://$ALB_ADDRESS"
echo ""

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_ADDRESS" --connect-timeout 10 || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "  ✓ HTTP Test PASSED (Status: $HTTP_STATUS)"
    echo ""
    echo "  Response:"
    curl -s "http://$ALB_ADDRESS" | head -20
else
    echo "  ✗ HTTP Test FAILED (Status: $HTTP_STATUS)"
    echo "  Note: ALB may still be warming up. Try again in a minute."
fi

echo ""
echo "=============================================="
echo "  Deployment Summary"
echo "=============================================="
echo ""
echo "  Cluster:   $CLUSTER_NAME"
echo "  Namespace: $NAMESPACE"
echo "  ALB URL:   http://$ALB_ADDRESS"
echo ""
echo "  RBAC Resources:"
echo "  - Role: developer-role (namespace: development)"
echo "  - ClusterRole: viewer-role"
echo ""
echo "  To cleanup: ./scripts/cleanup-example.sh"
echo ""
