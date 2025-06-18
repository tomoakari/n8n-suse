# n8n CloudRun デプロイメントガイド - 動作確認済み版 🚀

このプロジェクトでは、n8nワークフローオートメーションツールをGoogle Cloud Runにデプロイする方法を提供します。

## ✅ 動作確認済み推奨スクリプト

**🎯 推奨**: `deploy-cloudrun-optimized.sh` - **動作確認済み**

```bash
# 動作確認済みの推奨デプロイ方法
chmod +x deploy-cloudrun-optimized.sh
./deploy-cloudrun-optimized.sh
```

## 📋 前提条件

- Google Cloud Platform アカウント
- gcloud CLI インストール済み
- Docker インストール済み
- 適切なGCP権限（Cloud Run、Cloud Build、Cloud Storage）

## 🚀 クイックスタート（推奨方法）

### 1. プロジェクト設定

```bash
# リポジトリをクローン
git clone https://github.com/tomoakari/n8n-suse.git
cd n8n-suse

# 推奨スクリプトの設定を編集
vim deploy-cloudrun-optimized.sh
```

### 2. 重要な設定項目

`deploy-cloudrun-optimized.sh`ファイル内の以下の項目を変更してください：

```bash
PROJECT_ID="your-gcp-project-id"     # ← あなたのGCPプロジェクトID
REGION="asia-northeast1"             # ← 希望のリージョン
SERVICE_NAME="n8n-service"           # ← CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"           # ← Dockerイメージ名
```

### 3. デプロイ実行

```bash
# 推奨スクリプトを実行
chmod +x deploy-cloudrun-optimized.sh
./deploy-cloudrun-optimized.sh
```

## 📁 主要ファイル

```
n8n-suse/
├── deploy-cloudrun-optimized.sh    # 🌟 推奨：動作確認済み
├── Dockerfile                      # n8n用カスタムDockerfile
├── cloudrun-service.yaml           # CloudRunサービス定義
├── deploy.sh                       # 通常版デプロイスクリプト
├── deploy-sqlite.sh                # SQLite専用デプロイスクリプト
└── README.md                       # このファイル
```

## ⚙️ 推奨設定の特徴

### 🎯 `deploy-cloudrun-optimized.sh` の最適化

- ✅ **Task Runners無効** → CloudRunで安定動作
- ✅ **軽量設定** → メモリ使用量削減  
- ✅ **基本機能重視** → 起動速度向上
- ✅ **認証設定** → セキュリティ対応
- ✅ **パーミッション問題解決** → Cloud Storage FUSE対応

## 🔐 セキュリティ設定

### Basic認証の有効化（推奨）

動作確認後、セキュリティのためBasic認証を有効化：

```bash
# 環境変数でBasic認証を有効化
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password
```

## 🛠️ トラブルシューティング

### 動作確認済みの解決方法

**推奨スクリプト使用時の設定:**

```bash
# CloudRun最適化設定
N8N_RUNNERS_ENABLED=false           # Task Runners無効
N8N_SECURE_COOKIE=false             # CloudRun対応
N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true
N8N_METRICS=false                   # 軽量化
N8N_LOG_LEVEL=warn                  # ログ最小化
```

### ログ確認

```bash
# CloudRunログを確認
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=n8n-service" --limit 10 --format "table(timestamp,textPayload)"
```

## 🔧 カスタマイズ

### 環境変数の追加

推奨スクリプト内で環境変数を追加：

```bash
--set-env-vars CUSTOM_VAR=custom_value
```

### リソース調整

```bash
--memory 1Gi        # メモリ調整
--cpu 1             # CPU調整
--concurrency 100   # 同時接続数
```

## 🆕 動作確認済み設定

- ✅ CloudRun でのn8n安定動作
- ✅ Task Runners問題回避
- ✅ SQLite MISUSE エラー解決
- ✅ パーミッション警告対応
- ✅ Cannot GET / エラー解消

## 📚 参考リンク

- [n8n公式ドキュメント](https://docs.n8n.io/)
- [Cloud Run ドキュメント](https://cloud.google.com/run/docs)
- [n8n環境変数](https://docs.n8n.io/hosting/environment-variables/)

## 🤝 サポート

問題が発生した場合：
1. まず推奨スクリプト `deploy-cloudrun-optimized.sh` を使用
2. Cloud Runログを確認
3. 設定項目を再確認

---

**Happy Automating with CloudRun! 🎉**
