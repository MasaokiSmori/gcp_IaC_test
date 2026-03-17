project_id       = "erp-dataplatform-stg"
region           = "asia-northeast1"
subnet_cidr      = "10.1.0.0/24" # prod (10.0.0.0/24) と重複しないよう別セグメントを使用
workspace_domain = "example.com"  # TODO: 実際のドメインに変更すること
github_org       = "your-org"     # TODO: 実際の GitHub org に変更すること
github_repo      = "your-repo"                                    # TODO: 実際のリポジトリ名に変更すること
github_repo_url  = "git@github.example.com:your-org/your-repo.git" # TODO: 実際の SSH URL に変更すること
