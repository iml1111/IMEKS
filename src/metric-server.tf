# https://artifacthub.io/packages/helm/metrics-server/metrics-server
resource "helm_release" "metrics_server" {
  namespace       = "kube-system"
  name            = "metrics-server"
  chart           = "metrics-server"
  #version         = "3.11.0"
  repository      = "https://kubernetes-sigs.github.io/metrics-server/"
  cleanup_on_fail = true
  replace         = true

  set {
    name  = "image.repository"
    value = "registry.k8s.io/metrics-server/metrics-server"
  }
  set {
    name  = "image.pullPolicy"
    value = "Always"
  }
  set {
    name  = "replicas"
    value = 2
  }

  depends_on = [
    module.eks
  ]
}