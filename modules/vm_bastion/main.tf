# DAG デプロイ用 on-demand VM
# DS が SSH 接続して以下を実行するための踏み台:
#   - terraform apply (composer-stg の作成・削除)
#   - git pull && bash scripts/deploy_dags.sh (DAG 同期)
resource "google_compute_instance" "bastion" {
  project      = var.project_id
  name         = "vm-${var.env}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    # パブリック IP なし - IAP SSH トンネル経由のみアクセス可
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  # IAP SSH ファイアウォールルール用のネットワークタグ
  tags = ["iap-ssh"]

  # 停止状態で作成 (on-demand 運用。DS が必要なときだけ起動する)
  desired_status = "TERMINATED"

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e

    MARKER="/var/lib/vm-bastion-provisioned"

    # COMPOSER_ENV_NAME を /etc/environment に永続化
    # scripts/deploy_dags.sh がこの変数を参照して gcloud describe の対象を特定する
    grep -qxF 'COMPOSER_ENV_NAME=${var.composer_env_name}' /etc/environment \
      || echo 'COMPOSER_ENV_NAME=${var.composer_env_name}' >> /etc/environment

    # 初回プロビジョニング済みならパッケージインストールをスキップ
    if [ ! -f "$MARKER" ]; then
      # git と Google Cloud SDK のインストール
      apt-get update -q
      apt-get install -y git google-cloud-sdk gnupg software-properties-common

      # Terraform のインストール (バージョン固定 - CI/CD と合わせること)
      curl -fsSL https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/hashicorp.list
      apt-get update -q && apt-get install -y terraform=${var.terraform_version}-1

      touch "$MARKER"
    fi

    # リポジトリの自動クローン (初回のみ)
    REPO_DIR="/opt/repo"
    if [ ! -d "$REPO_DIR/.git" ]; then
      git clone ${var.github_repo_url} "$REPO_DIR"
      chmod -R 775 "$REPO_DIR"
    fi
  EOT
}

# IAP SSH を許可するファイアウォールルール
# gcloud compute ssh vm-[env] --tunnel-through-iap でアクセスする
resource "google_compute_firewall" "iap_ssh" {
  project  = var.project_id
  name     = "allow-iap-ssh-${var.env}"
  network  = var.network_name
  priority = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # GCP IAP のソース IP レンジ (固定)
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}
