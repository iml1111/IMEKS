terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "alekc/kubectl"
    }
  }
  #   backend "s3" {
  #     bucket         = "imeks-terraform-states"
  #     key            = "imeks.terraform.tfstate"
  #     region         = "ap-northeast-2"
  #     encrypt        = true
  #     dynamodb_table = "imeks-terraform-lock"
  #     acl            = "bucket-owner-full-control"
  #   }
}