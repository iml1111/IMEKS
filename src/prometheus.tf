# https://artifacthub.io/packages/helm/prometheus-community/prometheus
resource "helm_release" "prometheus" {
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  #version    = "25.4.0"

  name            = "prometheus"
  namespace       = "prometheus"
  cleanup_on_fail = true
  replace         = true

  depends_on = [
    module.eks,
    kubernetes_namespace.prometheus,
    kubectl_manifest.gp3_light_storageclass
  ]
}