# https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v19.19.0/modules/karpenter
# https://artifacthub.io/packages/helm/karpenter/karpenter
# https://github.com/aws/karpenter

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  #version = "v19.19.0"

  cluster_name = module.eks.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  create_iam_role                 = false
  iam_role_arn                    = module.eks.eks_managed_node_groups["backend"].iam_role_arn

  depends_on = [
    kubernetes_namespace.karpenter,
  ]
}

resource "helm_release" "karpenter" {
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "v0.32.1"
  name                = "karpenter"
  namespace           = "karpenter"

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
  set {
    name  = "replicas"
    value = 2
  }

  depends_on = [
    kubernetes_namespace.karpenter,
  ]
}


# Frontend nodegroup
resource "kubectl_manifest" "karpenter_frontend_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: karpenter-frontend-provisioner
    spec:
      requirements:
        - key: "node.kubernetes.io/instance-type" 
          operator: In
          values: ["c5a.xlarge"]
        - key: "topology.kubernetes.io/zone" 
          operator: In
          values: ["${var.region}a", "${var.region}c"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
      limits:
        resources:
          cpu: 1000
          memory: 1000Gi
      providerRef:
        name: frontend-template
      ttlSecondsUntilExpired: 2592000
      ttlSecondsAfterEmpty: 30
      labels:
        nodegroup-type: ${var.cluster_name}-${var.stage}-frontend    
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_backend_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: karpenter-backend-provisioner
    spec:
      requirements:
        - key: "node.kubernetes.io/instance-type" 
          operator: In
          values: ["c5a.xlarge"]
        - key: "topology.kubernetes.io/zone" 
          operator: In
          values: ["${var.region}a", "${var.region}c"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
      limits:
        resources:
          cpu: 1000
          memory: 1000Gi
      providerRef:
        name: backend-template
      ttlSecondsUntilExpired: 2592000
      ttlSecondsAfterEmpty: 30
      labels:
        nodegroup-type: ${var.cluster_name}-${var.stage}-backend   
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_frontend_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: frontend-template
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        Name: ${var.cluster_name}-${var.stage}-frontend-karpenter
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_backend_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: backend-template
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        Name: ${var.cluster_name}-${var.stage}-backend-karpenter
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
