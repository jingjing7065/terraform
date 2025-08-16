# Terraform プロジェクト
1. **EC2 デプロイ** (`terraform_ec2`)
- AWS リージョン `ap-northeast-1` にリソースを作成
- Key Pair を使用して EC2 に SSH ログイン可能
- VPC、パブリックサブネット、インターネットゲートウェイ、ルートテーブルを作成
- セキュリティグループで SSH(22) と HTTP(80) を許可
- EC2 インスタンスに Nginx を自動インストール
2. **EKS クラスター デプロイ** (`terraform_eks`)
-—eks
- AWS リージョン `ap-northeast-1` にリソースを作成
- VPC、パブリック/プライベート/内部サブネットを作成
- NAT Gateway を使用してプライベートサブネットからのインターネットアクセスを提供
- EKS クラスターを作成し、AWS IAM ユーザーに管理アクセスを付与
- マネージドノードグループ（`m6i.large`、AL2023 AMI）を作成
- Kubernetes プロバイダー設定により、Terraform から Helm / Kubernetes リソースを管理可能
- EKS アドオン（coredns, kube-proxy, VPC CNI, eks-pod-identity-agent）を自動インストール
-—helm（Prometheus + Grafana）
- 既存 EKS クラスターの状態を Terraform Remote State から取得
- Kubernetes プロバイダーと Helm プロバイダーを設定
- `monitoring` 名前空間を作成
- `kube-prometheus-stack` Helm チャートをデプロイ
    - Alertmanager は無効化
    - Grafana 管理者ユーザー設定 (`admin / admin123`)
    - Grafana サービスは LoadBalancer で公開
    - Grafana 永続化ストレージは無効
# プロジェクト構成
  |—terraform
  |——terraform_ec2 # Terraform を使って EC2 インスタンスを作成
  |———EC2.tf
  |———output.tf
  |——terraform_eks
  |———eks # Terraform を使って EKS クラスターと Helm デプロイ
  |————main.tf  
  |————output.tf
  |————version.tf
  |———helm
  |————main.tf
