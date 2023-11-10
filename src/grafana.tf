# https://artifacthub.io/packages/helm/grafana/grafana
resource "helm_release" "grafana" {
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  #version    = "7.0.3"

  name             = "grafana"
  namespace        = "grafana"
  create_namespace = true
  cleanup_on_fail  = true

  depends_on = [
    module.eks,
    kubernetes_namespace.grafana,
    kubectl_manifest.gp3_light_storageclass
  ]

  values = [
    templatefile("./helm_values/grafana.yaml", {})
  ]

  set {
    name  = "replicas"
    value = 1
  }
  set {
    name  = "persistence.enabled"
    value = true
  }
  set {
    name  = "persistence.storageClassName"
    value = "gp3-light"
  }
  set {
    name  = "service.type"
    value = "ClusterIP"
  }
  set {
    name  = "adminUser"
    value = var.grafana_master_user_name
  }
  set {
    name  = "adminPassword"
    value = var.grafana_master_user_pw
  }
}
