# IMEKS
Boilerplate for Kubernetes Infrastructure As Code in AWS using Terraform (Updated at 2023-11-13)
![image](https://github.com/iml1111/IMEKS/assets/29897277/eb606a12-8a6c-4f6c-881b-e8155c39d283)

# Get Started
To build infrastructure, you need the following tools:
- AWS CLI
- Terraform CLI
- kubectl
```shell
$ terraform init
$ terraform plan
$ terraform apply --auto-approve
```

# Structure Summary
- Kubernetes 1.28+ on EKS
- 2AZ, Public/Private/Intra Subnets
- 2 Managed Nodegroups(Frontend, Backend)
- Cluster AutoScaling with Karpenter
  - AWS Node Termination Handler 
- Ingress Controller with AWS Load Balancer
- EFK Log Pipeline
  - Fleunt-bit
  - AWS Opensearch Service
  - Opensearch DashBoard (Kibana Alternative)
- Cluster Montioring
  - Prometheus
  - Grafana
  - K8s Metric Server
- Cert Manager, Etc.

## Terraform Modules
- [IRSAs in EKS 5.30.1](https://github.com/terraform-aws-modules/terraform-aws-iam/tree/v5.30.1/modules/iam-role-for-service-accounts-eks)
- [eks 19.19.0](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [kms 2.1.0](https://github.com/terraform-aws-modules/terraform-aws-kms)
- [karpenter v19.19.0](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v19.19.0/modules/karpenter)
- [vpc 5.1.2](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [vpc-endpoints 5.1.2](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/v5.1.2/modules/vpc-endpoints)

## Helm Release

- [aws-load-balancer-controller 1.6.2](https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller)
- [aws-node-termination-handler 0.21.0](https://artifacthub.io/packages/helm/aws/aws-node-termination-handler)
- [cert-manager v1.13.2](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
- [fluent-bit 0.39.1](https://artifacthub.io/packages/helm/fluent/fluent-bit)
- [prometheus 25.4.0](https://artifacthub.io/packages/helm/prometheus-community/prometheus)
- [grafana 7.0.3](https://artifacthub.io/packages/helm/grafana/grafana)
- [karpenter v0.32.1](https://artifacthub.io/packages/helm/karpenter/karpenter)
- [metrics-server 3.11.0](https://artifacthub.io/packages/helm/metrics-server/metrics-server)

