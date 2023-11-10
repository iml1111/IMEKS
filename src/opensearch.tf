# TODO: AWS OpenSearch Service로 변경
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain

# resource "aws_elasticsearch_domain" "log" {
#   domain_name           = var.es_domain_name
#   elasticsearch_version = "7.10"

#   # check at production (주로 사양 체크 필요)
#   cluster_config {
#     dedicated_master_enabled = false
#     # dedicated_master_count   = 3
#     # dedicated_master_type    = "t3.small.elasticsearch"
#     instance_count         = 2
#     instance_type          = "t3.small.elasticsearch"
#     zone_awareness_enabled = true
#     warm_enabled           = false
#     zone_awareness_config {
#       availability_zone_count = 2
#     }
#   }
#   # check at production
#   ebs_options {
#     ebs_enabled = true
#     volume_type = "gp3"
#     volume_size = 100
#     iops        = 3000
#     throughput  = 125
#   }
#   node_to_node_encryption {
#     enabled = true
#   }
#   encrypt_at_rest {
#     enabled = true
#   }
#   domain_endpoint_options {
#     enforce_https       = true
#     tls_security_policy = "Policy-Min-TLS-1-0-2019-07"
#   }
#   advanced_security_options {
#     enabled                        = true
#     internal_user_database_enabled = true
#     master_user_options {
#       master_user_name     = var.es_master_user_name
#       master_user_password = var.es_master_user_pw
#     }
#   }
#   # TODO: vpc_options VPC based private 구축 필요
#   tags = {
#     Author = var.author
#     Stage  = var.stage
#   }
# }

# resource "aws_elasticsearch_domain_policy" "log" {
#   domain_name = aws_elasticsearch_domain.log.domain_name

#   access_policies = <<POLICY
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Action": "es:*",
#         "Principal": "*",
#         "Effect": "Allow",
#         "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${var.es_domain_name}/*"
#       }
#     ]
#   }
#   POLICY
# }

# resource "null_resource" "update_alocados_fluent_bit_role_all_access" {
#   triggers = {
#     es_master_user_name = var.es_master_user_name
#     es_master_user_pw   = var.es_master_user_pw
#   }

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]

#     command = <<-EOT
#       curl -sS -u '${var.es_master_user_name}:${var.es_master_user_pw}' \
#           -X PATCH \
#           https://${aws_elasticsearch_domain.log.endpoint}/_opendistro/_security/api/rolesmapping/all_access\?pretty \
#           -H 'Content-Type: application/json' \
#           -d'
#       [
#         {
#           "op": "add", "path": "/backend_roles", "value": ["${module.fluent_bit_irsa_role.iam_role_arn}"]
#         }
#       ]
#       '
#     EOT
#   }

#   depends_on = [
#     aws_elasticsearch_domain.log
#   ]
# }