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
  default     = "1.28"
}

variable "search_domain_name" {
  type        = string
  description = "OpenSearch Domain Name"
  default     = "imeks-dev-log"
}

variable "grafana_master_name" {
  type        = string
  description = "Grafana Master Username"
  default     = "imeks_grafana"
}

variable "grafana_master_pw" {
  type        = string
  description = "Grafana Master User Pw"
  default     = "!imeks_password"
}

variable "search_master_name" {
  type        = string
  description = "OpenSearch Master Username"
  default     = "imeks_opensearch"
}

variable "search_master_pw" {
  type        = string
  description = "OpenSearch Master User Pw"
  default     = "!Imeks_password123"
}

variable "iam_username" {
  type        = string
  description = "IAM User Name"
  default     = "terraform"
}