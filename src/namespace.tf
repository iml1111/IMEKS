resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}
