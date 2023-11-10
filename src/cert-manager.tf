# https://artifacthub.io/packages/helm/cert-manager/cert-manager
resource "helm_release" "cert-manager" {
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  name            = "cert-manager"
  namespace       = "cert-manager"
  cleanup_on_fail = true
  replace         = true

  depends_on = [
    module.eks,
    kubernetes_namespace.cert_manager
  ]
  set {
    name  = "installCRDs"
    value = true
  }
}