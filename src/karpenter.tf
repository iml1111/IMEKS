# https://karpenter.sh/docs/upgrading/upgrade-guide/
# https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v19.19.0/modules/karpenter
# https://github.com/aws/karpenter
# TODO: 각 노드 클래스마다 다른 IAM Role을 할당할 수 있나?

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  #version = "v19.20.0"

  cluster_name = module.eks.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  enable_karpenter_instance_profile_creation = true
  create_iam_role                 = false
  iam_role_arn                    = module.eks.eks_managed_node_groups["backend"].iam_role_arn

  tags = {
    Stage  = var.stage
    Author = var.author
  }
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
    module.karpenter,
  ]
}

resource "kubectl_manifest" "karpenter_frontend_nodepool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: karpenter-frontend-nodepool
    spec:
      disruption:
        consolidateAfter: 30s
        consolidationPolicy: WhenEmpty
        expireAfter: 720h0m0s
      limits:
        cpu: 1k
        memory: 1000Gi
      template:
        metadata:
          labels:
            nodegroup-type: ${var.cluster_name}-${var.stage}-frontend
        spec:
          nodeClassRef:
            name: frontend-nodeclass
          requirements:
          - key: node.kubernetes.io/instance-type
            operator: In
            values:
            - c5a.xlarge
          - key: topology.kubernetes.io/zone
            operator: In
            values:
            - ${var.region}a
            - ${var.region}c
          - key: karpenter.sh/capacity-type
            operator: In
            values:
            - spot
            - on-demand
          - key: kubernetes.io/os
            operator: In
            values:
            - linux
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64  
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_backend_nodepool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: karpenter-backend-nodepool
    spec:
      disruption:
        consolidateAfter: 30s
        consolidationPolicy: WhenEmpty
        expireAfter: 720h0m0s
      limits:
        cpu: 1k
        memory: 1000Gi
      template:
        metadata:
          labels:
            nodegroup-type: ${var.cluster_name}-${var.stage}-backend
        spec:
          nodeClassRef:
            name: backend-nodeclass
          requirements:
          - key: node.kubernetes.io/instance-type
            operator: In
            values:
            - c5a.xlarge
          - key: topology.kubernetes.io/zone
            operator: In
            values:
            - ${var.region}a
            - ${var.region}c
          - key: karpenter.sh/capacity-type
            operator: In
            values:
            - spot
            - on-demand
          - key: kubernetes.io/os
            operator: In
            values:
            - linux
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_frontend_nodeclass" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: frontend-nodeclass
    spec:
      amiFamily: AL2
      role: ${module.eks.eks_managed_node_groups["frontend"].iam_role_name}
      securityGroupSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${module.eks.cluster_name}
      subnetSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        Name: ${var.cluster_name}-${var.stage}-frontend-karpenter
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_backend_nodeclass" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: backend-nodeclass
    spec:
      amiFamily: AL2
      role: ${module.eks.eks_managed_node_groups["backend"].iam_role_name}
      securityGroupSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${module.eks.cluster_name}
      subnetSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        Name: ${var.cluster_name}-${var.stage}-backend-karpenter
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
