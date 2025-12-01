# =============================================================================
# Metrics Server
# =============================================================================

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"
  namespace  = "kube-system"

  values = [
    file("${path.module}/../../helm_values/metrics-server.yaml")
  ]

  depends_on = [
    module.alb_controller_irsa
  ]
}
