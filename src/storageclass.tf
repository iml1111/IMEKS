# https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/511dd1ce45658ea64b1bd701118f7cc13632a741/docs/README.md

resource "kubectl_manifest" "gp3_storageclass" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: gp3
    provisioner: ebs.csi.aws.com
    parameters:
      type: gp3
      csi.storage.k8s.io/fstype: ext4
  YAML

  depends_on = [
    module.eks
  ]
}

resource "kubectl_manifest" "gp3_light_storageclass" {
  yaml_body = <<-YAML
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: gp3-light
    provisioner: ebs.csi.aws.com
    parameters:
      type: gp3
      csi.storage.k8s.io/fstype: ext4
      iopsPerGB: "3000"
      throughput: "125"
      encrypted: "false"
  YAML

  depends_on = [
    module.eks
  ]
}