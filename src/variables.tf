variable "author" {
  type        = string
  description = "Author of the deployment"
  default     = "IML"
}

variable "stage" {
  type        = string
  description = "Product Stage"
  default     = "dev"
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "VPC Name"
  default     = "imeks"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
  default     = "imeks"
}

variable "cluster_version" {
  type        = string
  description = "EKS Cluster Version"
  default     = "1.27"
}

variable "grafana_master_user_name" {
  type        = string
  description = "Grafana Master Username"
  default     = "imeks_grafana"
}

variable "grafana_master_user_pw" {
  type        = string
  description = "Grafana Master User Pw"
  default     = "!imeks_password"
}

variable "kms_encryption_ebs_policy_name" {
  type        = string
  description = "KMS Encryption EBS Policy Name"
  default     = "eks-dev-kms-encryption-ebs"
}
