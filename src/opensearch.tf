resource "aws_opensearch_domain" "log" {
  domain_name = var.search_domain_name
  #engine_version = "OpenSearch_2.11"

  cluster_config {
    dedicated_master_enabled = false
    dedicated_master_count   = 3
    dedicated_master_type    = "t3.small.search"
    instance_count           = 2
    instance_type            = "t3.small.search"
    zone_awareness_enabled   = true
    warm_enabled             = false
    zone_awareness_config {
      availability_zone_count = 2
    }
  }
  # check at production
  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 100
    iops        = 3000
    throughput  = 125
  }
  node_to_node_encryption {
    enabled = true
  }
  encrypt_at_rest {
    enabled = true
  }
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-0-2019-07"
  }
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.search_master_name
      master_user_password = var.search_master_pw
    }
  }
  # TODO: vpc_options VPC based private 구축 필요
  tags = {
    Author = var.author
    Stage  = var.stage
  }
}

data "aws_iam_policy_document" "log_access" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["es:*"]
    resources = ["${aws_opensearch_domain.log.arn}/*"]
  }
}

resource "aws_opensearch_domain_policy" "log" {
  domain_name     = aws_opensearch_domain.log.domain_name
  access_policies = data.aws_iam_policy_document.log_access.json
}

resource "null_resource" "update_fluent_bit_role_all_access" {
  triggers = {
    search_master_name  = var.search_master_name
    search_master_pw    = var.search_master_pw
    fluent_bit_role_arn = module.fluent_bit_irsa_role.iam_role_arn
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      curl -sS -u '${var.search_master_name}:${var.search_master_pw}' \
          -X PATCH \
          https://${aws_opensearch_domain.log.endpoint}/_opendistro/_security/api/rolesmapping/all_access\?pretty \
          -H 'Content-Type: application/json' \
          -d'
      [
        {
          "op": "add", "path": "/backend_roles", "value": ["${module.fluent_bit_irsa_role.iam_role_arn}"]
        }
      ]
      '
    EOT
  }

  depends_on = [
    aws_opensearch_domain.log,
    aws_opensearch_domain_policy.log,
    module.fluent_bit_irsa_role
  ]
}