// https://artifacthub.io/packages/helm/aws/aws-node-termination-handler
resource "helm_release" "aws_node_termination_handler" {
  repository = "https://aws.github.io/eks-charts/"
  chart      = "aws-node-termination-handler"
  #version    = "0.21.0"

  name            = "aws-node-termination-handler"
  namespace       = "kube-system"
  cleanup_on_fail = true
  replace         = true

  depends_on = [
    module.eks,
    kubernetes_namespace.cert_manager
  ]
  set {
    name  = "awsRegion"
    value = var.region
  }
  set {
    name  = "checkASGTagBeforeDraining"
    value = false
  }
  set {
    name  = "enableSpotInterruptionDraining"
    value = true
  }
  set {
    name  = "enableScheduledEventDraining"
    value = true
  }
  set {
    name  = "enableRebalanceMonitoring"
    value = true
  }
  set {
    name  = "enableRebalanceDraining"
    value = true
  }
  set {
    name  = "nodeSelector.karpenter\\.sh/capacity-type"
    value = "spot"
  }
  set {
    name  = "nodeSelector.nodegroup-type"
    value = "${var.eks_stage}-frontend"
  }
  set {
    name  = "nodeSelector.nodegroup-type"
    value = "${var.eks_stage}-backend"
  }
}