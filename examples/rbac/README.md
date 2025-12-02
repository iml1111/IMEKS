# EKS RBAC Examples

하이브리드 인증/권한 관리를 위한 Kubernetes RBAC 예시입니다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        IAM User/Role                            │
│              (arn:aws:iam::123456789012:role/TeamRole)          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EKS Access Entry                             │
│                 (Terraform에서 설정)                             │
│         kubernetes_groups = ["team-developers"]                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Kubernetes RoleBinding                        │
│                    (이 예시 파일들)                              │
│         subjects.Group = "team-developers"                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Kubernetes Role                             │
│              (세밀한 리소스/동작 권한 정의)                      │
└─────────────────────────────────────────────────────────────────┘
```

## 사용 방법

### Step 1: Terraform에서 IAM to K8s 그룹 매핑

`terraform.tfvars`:

```hcl
# Admin - AWS 정책으로 즉시 권한 부여
# Format: "user/name" or "role/name" (ARN is auto-generated)
eks_admin_principals = [
  "user/admin"
]

# 일반 사용자 - K8s 그룹 매핑 (RBAC에서 권한 제어)
eks_access_entries = {
  "backend-team" = {
    principal         = "role/BackendTeamRole"
    kubernetes_groups = ["backend-developers"]
  }
  "frontend-team" = {
    principal         = "role/FrontendTeamRole"
    kubernetes_groups = ["frontend-developers"]
  }
  "viewer" = {
    principal         = "user/viewer"
    kubernetes_groups = ["viewers"]
  }
}
```

### Step 2: RBAC 리소스 배포

```bash
# 개발자 권한 (네임스페이스 범위)
kubectl apply -f developer-role.yaml

# 뷰어 권한 (클러스터 범위)
kubectl apply -f viewer-role.yaml
```

### Step 3: 권한 확인

```bash
# 특정 사용자의 권한 확인
kubectl auth can-i list pods --as-group=backend-developers

# 모든 권한 확인
kubectl auth can-i --list --as-group=backend-developers
```

## 예시 파일

| 파일 | 설명 | 범위 |
|-----|------|------|
| `developer-role.yaml` | 개발자용 Role/RoleBinding | Namespace |
| `viewer-role.yaml` | 뷰어용 ClusterRole/ClusterRoleBinding | Cluster |

## 커스터마이징

### 네임스페이스 변경

`developer-role.yaml`의 namespace를 변경:

```yaml
metadata:
  name: developer-role
  namespace: my-namespace  # 원하는 네임스페이스로 변경
```

### 권한 추가/제거

Role의 rules 섹션을 수정:

```yaml
rules:
  - apiGroups: [""]
    resources: ["pods", "services"]  # 원하는 리소스
    verbs: ["get", "list", "watch"]  # 원하는 동작
```

### 새 그룹 추가

RoleBinding의 subjects에 그룹 추가:

```yaml
subjects:
  - kind: Group
    name: my-new-group  # eks_access_entries의 kubernetes_groups와 매칭
    apiGroup: rbac.authorization.k8s.io
```

## AWS EKS Access Policies vs RBAC

| 방식 | 장점 | 단점 |
|-----|------|------|
| **AWS 정책** | 간단, AWS 관리, CloudTrail 감사 | Admin/Edit/View 등 고정 정책만 |
| **K8s RBAC** | 완전 커스텀 가능, 리소스/동작 단위 제어 | 별도 YAML 관리 필요 |

**권장**: Admin은 AWS 정책 (`eks_admin_arns`), 세밀한 권한은 RBAC

## 참고 자료

- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [EKS Access Entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
