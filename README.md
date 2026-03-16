# Data Infrastructure Specification (GCP + Terraform)

## 1. プロジェクト概要
本ドキュメントは、ERPデータをソースとしたデータ分析基盤のインフラ構成を定義する。
セキュリティを最優先し、VPC Service Controlsを用いた境界防御と、GitHub ActionsによるCI/CDを基本戦略とする。

## 2. システムアーキテクチャ
* Cloud Provider: Google Cloud (GCP)
* IaC Tool: Terraform (v1.5.0以上推奨)
* Region: asia-northeast1 (東京) 固定
* Environment: prod (本番), stg (検証) の2環境。それぞれ独立したGCPプロジェクトを用意する。
  * Project ID: erp-dataplatform-prod / erp-dataplatform-stg
* ERP Source: 別GCPプロジェクト上に存在する外部システム。VPC SC境界を跨いだデータ連携を行う。

### 2.1 コンポーネント一覧

| コンポーネント | 環境 | 稼働形態 | 管理方法 | 用途 |
|---|---|---|---|---|
| composer-prod-runner | prod | **常時稼働** | Terraform (CI/CD) | 本番DAGのスケジュール実行 |
| vm-prod | prod | on-demand | Terraform (CI/CD, 停止状態で作成) | SSH接続によるDAGデプロイ操作 |
| vm-stg | stg | on-demand | Terraform (CI/CD, 停止状態で作成) | SSH接続によるgit操作・DAGデプロイ・composer-stg管理 |
| composer-stg | stg | on-demand | **Terraform (count方式, vm-stgから直接apply)** | DSによるDAG動作テスト |

> **composer-stg の管理方針:**
> `var.is_stg_active` フラグで存在を制御する。デフォルトは `false`（リソース未作成）。
> CI/CD は常に `is_stg_active=false` を明示的に渡すため、composer-stg には触れない。
> DSは vm-stg 上で terraform apply -target を使い、任意のタイミングで作成・削除する。
> この方式により、stg と prod で同一 Terraform モジュールを使うことが保証され、Airflow バージョンの差異が生じない。

### 2.2 DAGデプロイの仕組み

DAGファイルの本番・stg反映は、VMにSSH接続して `scripts/deploy_dags.sh` を実行することで行う。
同期先 Composer 環境名は VM 起動時に Terraform が設定した `COMPOSER_ENV_NAME` 環境変数で切り替える。
`DAG_GCS_PREFIX` は gcloud CLI で動的に取得するため、Terraform 適用時点で Composer が存在しなくても問題ない。

```bash
# scripts/deploy_dags.sh (prod/stg 共通の処理概要)
source /etc/environment   # COMPOSER_ENV_NAME を読み込む
DAG_GCS_PREFIX=$(gcloud composer environments describe "${COMPOSER_ENV_NAME}" ...)
gsutil -m rsync -r -d ./dags/ "${DAG_GCS_PREFIX}/"
```

## 3. ディレクトリ構成
```
gcp/
├── .github/workflows/        # CI/CD (WIF認証による自動デプロイ)
|   ├── terraform.yml         # infra変更時のみ: fmt→plan→apply
|   └── dag-sync.yml          # 将来的な自動同期用 (現状は手動デプロイ運用)
├── modules/                  # 再利用可能なリソース部品
│   ├── vpc/                  # VPC, Cloud NAT, Firewall
│   ├── vpc_sc/               # VPC Service Controls (prod 境界・ingress/egress ルール)
│   ├── storage/              # GCS Buckets (Lifecycle管理含む)
│   ├── bigquery/             # Datasets & Tables
│   ├── composer/             # Cloud Composer 3 (prod-runner・stg 共通モジュール)
│   ├── vm_bastion/           # DAGデプロイ用 on-demand VM (Terraform インストール済み)
│   └── iam/                  # IAM Roles, WIF, Service Accounts
├── scripts/
│   └── deploy_dags.sh        # DAG を Composer の GCS バケットへ同期
├── environments/
│   ├── prod/                 # 本番環境パラメータ
│   └── stg/                  # 検証環境パラメータ (is_stg_active で composer-stg を制御)
└── dags/                     # DAG ファイル管理ディレクトリ
```

## 4. ネットワーク設計 (Networking)
* VPC: prod/stg それぞれのGCPプロジェクトに独立したVPCを構築。
* Private Access: BigQueryおよびGCSへのアクセスは、承認されたVPC内からのみ許可する。
* 外部ネットワーク（Public Internet）からのアクセスはIAMレベルだけでなく、VPC Service Controls (VPC SC) で遮断する。
* VPC SC 境界: **ERPソースプロジェクトは境界外**（別組織・別管理）として扱う。ERP→prodのデータ連携は境界をまたぐため、`modules/vpc_sc` で以下のルールを明示設定する。

| 方向 | 送信元 | 送信先 | 許可サービス | 用途 |
|------|--------|--------|-------------|------|
| Ingress | ERP SA | prod GCS | `storage.objects.create/list` | ERP→生データアップロード |
| Ingress | stg Composer SA | prod BQ | `bigquery.*` | stg DAG による prod erp_raw 参照 |
| Egress | prod Composer SA | ERP プロジェクト BQ | `bigquery.*` | DAG がプル型でERPデータを取得する場合 |

> **Egress について**: ERP への書き戻しは行わない設計のため、Egress は BigQuery 読み取りに限定する。プッシュ型（ERP→GCS）で完結する場合は Egress ルール自体が不要。
* Cloud NAT: Composer等のPrivate Nodeがインターネットへ抜けるために配置（アウトバウンドのみ）。
* VM へのSSH接続: 直接SSH不可。IAP (Identity-Aware Proxy) トンネル経由のみ許可。

## 5. データ・ストレージ設計 (Data Layer)

### 5.1 BigQuery Datasets
| Dataset | 用途 | テーブル管理方法 |
|---------|------|----------------|
| erp_raw | ERPからの生データロード先 | 初期スキーマのみ手動作成、以降はDAGで更新 |
| erp_stg | クレンジング・中間処理用 | 同上 |
| erp_mart | ビジネスサイド公開用（大判テーブル） | 同上 |
| prod_test | (Prodのみ) 開発者用の砂場 | 同上 |

### 5.2 GCS Buckets
* **erp-ingest-raw-[env]**: 日次のERPデータアップロード用。
  * Lifecycle: 作成から365日後にオブジェクトを削除。
* **terraform-state-[env]**: Terraformの backend 用。
  * アクセス制限の詳細はセクション6を参照。

## 6. IAM & セキュリティ要件

### 6.1 ユーザーロール
ユーザー管理は Google Workspace のグループアカウントで行う。

| ロール | Google Workspace グループ | Prod権限 | Stg権限 |
|--------|--------------------------|----------|---------|
| Senior DS | g-datascience-snr@[workspace-domain] | BigQuery Admin, IAP SSH (vm-prod) | Owner 相当, IAP SSH (vm-stg) |
| Junior DS | g-datascience-jnr@[workspace-domain] | BQ Data Viewer, Job User, prod_test Dataset編集 | Editor 相当, IAP SSH (vm-stg) |

> **IAP SSH アクセスについて**: Junior DS は stg VM へのSSH のみ許可。prod VM（vm-prod）へのアクセスは Senior DS に限定する。

### 6.2 Service Accounts
| SA | 権限 |
|----|------|
| sa-composer-prod-runner | prod プロジェクト内 GCS/BQ の読み書き |
| sa-composer-stg | stg プロジェクト内 GCS/BQ の読み書き ＋ **prod の erp_raw Dataset への読み取り権限** |
| sa-vm-prod | composer-prod-runner の GCS バケットへの書き込み (`roles/storage.objectAdmin`) |
| sa-vm-stg | GCS 書き込み (`roles/storage.objectAdmin`) ＋ `roles/composer.admin` ＋ `roles/iam.serviceAccountUser` (on sa-composer-stg) ＋ `roles/viewer` (Terraform refresh 用) |

### 6.3 Terraform State へのアクセス制限
* **prod-state**: 人間は直接アクセス不可。WIF経由のTerraform SAのみ書き込み可。
* **stg-state**: 基本はprod-stateと同じ制限。Senior DSグループには読み取り専用権限を付与（デバッグ用途）。
  * **sa-vm-stg も stg-state への書き込みを許可する**（vm-stg 上での terraform apply のため）。

### 6.4 認証
* Workload Identity Federation (WIF): リポジトリ単位で GitHub Actions 専用のプールを作成し、JSONキーファイルを使わずにデプロイを行う。
  * スコープ: 本リポジトリ (`refs/heads/main` へのマージ時のみ apply を許可）。
* VM へのSSH: `gcloud compute ssh [vm-name] --tunnel-through-iap` を使用。公開鍵認証を前提とし、パスワード認証は無効化。

### 6.5 VPC SC 適用に必要な初期情報
`environments/prod/terraform.tfvars` に以下の値を設定すること。

| 変数 | 取得コマンド |
|------|------------|
| `org_id` | `gcloud organizations list --format='value(name)'` |
| `access_policy_id` | `gcloud access-context-manager policies list --organization=ORG_ID` |
| `prod_project_number` | `gcloud projects describe erp-dataplatform-prod --format='value(projectNumber)'` |
| `erp_project_number` | `gcloud projects describe ERP_PROJECT_ID --format='value(projectNumber)'` |
| `erp_sa_email` | ERP チームから提供（生データアップロード用 SA のメール） |
| `stg_project_id` | デフォルト `erp-dataplatform-stg`。変更時のみ明示設定。 |

> **`org_id` について**: GitHub Actions SA に VPC SC 境界の管理権限（`roles/accesscontextmanager.policyAdmin`）を付与するため、組織レベルで IAM バインディングを行う。プロジェクトレベルの `roles/editor` では VPC SC の操作権限が不足するため必須。

## 7. 運用フロー

### 7.1 STG: DAG開発・テストフロー (DS向け)

Cloud Composer 3 はGKE Autopilotベースのため、Composer環境へのSSH接続は不可。
git操作・デプロイ操作・composer-stgのライフサイクル管理はすべて vm-stg 上で行う。

```
① vm-stg を起動・SSH接続
   gcloud compute instances start vm-stg --zone=asia-northeast1-a --project=erp-dataplatform-stg
   gcloud compute ssh vm-stg --tunnel-through-iap --project=erp-dataplatform-stg

② vm-stg 内で composer-stg を作成 ※完了まで約20〜30分
   bash scripts/create_composer.sh

③ 【以下、修正が完了するまで繰り返す】
   ローカルで DAG を修正 → git add && git commit && git push

   vm-stg 上で (リポジトリルートから):
   git pull && bash scripts/deploy_dags.sh

   ブラウザで Airflow Web UI を開いて動作確認
   (stg は enable_private_endpoint=false のため Airflow Web UI へ直接アクセス可)

④ テスト完了 → PR をマージ → composer-stg を削除
   bash scripts/delete_composer.sh

⑤ vm-stg を停止
   gcloud compute instances stop vm-stg --zone=asia-northeast1-a --project=erp-dataplatform-stg
```

### 7.2 PROD: DAGデプロイフロー

```
① PR が main にマージされたことを確認
② vm-prod を起動・SSH接続
   gcloud compute instances start vm-prod --zone=asia-northeast1-a --project=erp-dataplatform-prod
   gcloud compute ssh vm-prod --tunnel-through-iap --project=erp-dataplatform-prod

③ vm-prod 上で (リポジトリルートから):
   git pull && bash scripts/deploy_dags.sh
   (main ブランチの内容が composer-prod-runner の GCS バケットへ同期される)

④ composer-prod-runner の Airflow Web UI で反映を確認
   (prod は enable_private_endpoint=true のため IAP トンネル経由でアクセス)

⑤ 確認完了 → vm-prod を停止
   gcloud compute instances stop vm-prod --zone=asia-northeast1-a --project=erp-dataplatform-prod
   (composer-prod-runner は常時稼働のため停止しない)
```

## 8. CI/CD パイプライン

### 8.1 Terraform ワークフロー
| トリガー | 処理 |
|---------|------|
| Pull Request | 該当環境の `terraform plan` を実行 |
| Merge to main | 該当環境の `terraform apply` を実行 |

Checks:
* `terraform fmt -check`
* `tflint --recursive` (非ブロック: 警告のみ、CI は継続)

パス絞り込み:
* Terraform ワークフロー: `paths: ['environments/**', 'modules/**']`
* DAG変更（`dags/**`）では Terraform ワークフローは起動しない。

**stg 環境の CI/CD における composer-stg の扱い:**
CI/CD は常に `-var="is_stg_active=false"` を明示的に渡す。
これにより、DSが手動で composer-stg を作成中であっても、CI/CD が誤って削除することを防ぐ。

### 8.2 DAG デプロイ
DAGの本番・stg反映はVM上での手動操作（`scripts/deploy_dags.sh`）で行う。
GitHub Actions による自動同期は行わない。

| 環境 | デプロイ方法 | タイミング |
|------|------------|----------|
| stg | vm-stg で `git pull && bash scripts/deploy_dags.sh` | DSが任意のタイミングで実行（開発ブランチ） |
| prod | vm-prod で `git pull && bash scripts/deploy_dags.sh` | main マージ後に実行 |
