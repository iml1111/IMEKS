# https://artifacthub.io/packages/helm/fluent/fluent-bit
# resource "helm_release" "fluentbit" {
#   repository = "https://fluent.github.io/helm-charts"
#   chart      = "fluent-bit"
#   #version    = "0.39.1"

#   name             = "fluent-bit"
#   namespace        = "fluent-bit"
#   create_namespace = true
#   cleanup_on_fail  = true

#   depends_on = [module.eks, kubernetes_namespace.fluent_bit]

#   values = [
#     templatefile("./helm_values/fluent-bit.yaml", {
#       region         = var.region
#       es_domain_name = aws_elasticsearch_domain.log.endpoint
#     })
#   ]
#   set {
#     name  = "clusterName"
#     value = var.cluster_name
#   }
#   set {
#     name  = "serviceAccount.name"
#     value = "fluent-bit"
#   }
#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.fluent_bit_irsa_role.iam_role_arn
#   }
# }