# n8n CloudRun デプロイメントガイド 🚀

このプロジェクトでは、n8nワークフローオートメーションツールをGoogle Cloud Runにデプロイする方法を提供します。

## 📋 前提条件

- Google Cloud Platform アカウント
- gcloud CLI インストール済み
- Docker インストール済み
- 適切なGCP権限（Cloud Run、Cloud Build、Cloud SQL、Cloud Storage）

## 🏗️ アーキテクチャ

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloud Run     │    │  Cloud Storage  │    │   Cloud SQL     │
│   (n8n App)    │────│   (File Data)   │    │  (Workflows)    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Users/APIs    │
                    │   (HTTPS)       │
                    └─────────────────┘
```

## 🚀 クイックスタート

### 1. プロジェクト設定

```bash
# リポジトリをクローン
git clone https://github.com/tomoakari/n8n-suse.git
cd n8n-suse

# デプロイスクリプトの設定を編集
vim deploy.sh
```

### 2. 重要な設定項目

`deploy.sh`ファイル内の以下の項目を変更してください：

```bash
PROJECT_ID="your-gcp-project-id"     # ← あなたのGCPプロジェクトID
REGION="asia-northeast1"             # ← 希望のリージョン
SERVICE_NAME="n8n-service"           # ← CloudRunサービス名
BUCKET_NAME="n8n-data-bucket"        # ← ユニークなバケット名
```

### 3. デプロイ実行

```bash
# デプロイスクリプトを実行
chmod +x deploy.sh
./deploy.sh
```

## 📁 ファイル構成

```
n8n-suse/
├── Dockerfile              # n8n用カスタムDockerfile
├── cloudrun-service.yaml   # CloudRunサービス定義
├── deploy.sh               # 自動デプロイスクリプト
├── fix-permissions.sh      # パーミッション修正スクリプト
└── README.md               # このファイル
```

## ⚙️ 設定オプション

### データベース選択

**SQLite（デフォルト）**
- 簡単セットアップ
- 小規模利用向け
- Cloud Storageにデータ保存

**PostgreSQL（推奨：本番環境）**
- 高可用性
- スケーラブル
- Cloud SQLインスタンス使用

### 永続化ストレージ

**Cloud Storage FUSE（Preview）**
```yaml
volumeMounts:
- name: n8n-storage
  mountPath: /home/node/.n8n

volumes:
- name: n8n-storage
  csi:
    driver: gcsfuse.csi.storage.gke.io
    volumeAttributes:
      bucketName: YOUR_BUCKET_NAME
```

## 🔐 セキュリティ設定

### Basic認証
```bash
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password
```

### 暗号化キー
```bash
# 自動生成される32文字のHEXキー
N8N_ENCRYPTION_KEY=your_32_char_hex_key
```

## 🔧 パーミッション問題の解決

このプロジェクトではCloud Storage FUSEを使用する際によく発生するパーミッション問題を自動的に解決します：

### 解決済みの問題
- `Permissions 0644 for n8n settings file are too wide` エラー
- Cloud Storage FUSE でのファイル権限問題
- CloudRun での Webhook 登録解除問題

### 実装された修正
```bash
# 環境変数による修正
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true

# 起動スクリプトによる修正
fix-permissions.sh  # 起動時にファイル権限を自動修正
```

## 🚨 重要な注意事項

1. **暗号化キーの保管**: デプロイ後に表示される暗号化キーを安全に保存してください
2. **Basic認証**: 本番環境では強固なパスワードを設定してください
3. **データベース**: 本番環境ではCloud SQLの使用を推奨します
4. **バックアップ**: 定期的にワークフローとデータのバックアップを取ってください

## 🛠️ トラブルシューティング

### よくある問題

**1. ポート8080エラー**
```bash
# Dockerfileでポート設定を確認
ENV N8N_PORT=8080
```

**2. データの永続化問題**
```bash
# Cloud Storageマウントが正しく設定されているか確認
gsutil ls gs://your-bucket-name/
```

**3. データベース接続エラー**
```bash
# Cloud SQLプロキシの設定を確認
gcloud sql instances describe your-instance
```

**4. パーミッション警告（解決済み）**
```
Permissions 0644 for n8n settings file /home/node/.n8n/config are too wide.
```
→ このエラーは自動的に修正されるように設定済みです ✅

### ログ確認

```bash
# CloudRunログを確認
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=n8n-service" --limit 50 --format "table(timestamp,textPayload)"
```

## 🔧 カスタマイズ

### 環境変数の追加

`cloudrun-service.yaml`または`deploy.sh`に環境変数を追加：

```yaml
env:
- name: CUSTOM_VAR
  value: "custom_value"
```

### リソース調整

```yaml
resources:
  limits:
    cpu: 2000m      # CPU増加
    memory: 4Gi     # メモリ増加
```

## 🆕 最新の更新

- ✅ Cloud Storage FUSE パーミッション問題の自動修正
- ✅ CloudRun 互換性の向上
- ✅ 起動時パーミッション修正スクリプト追加
- ✅ Webhook 登録解除問題の修正

## 📚 参考リンク

- [n8n公式ドキュメント](https://docs.n8n.io/)
- [Cloud Run ドキュメント](https://cloud.google.com/run/docs)
- [Cloud Storage FUSE](https://cloud.google.com/run/docs/configuring/services/cloud-storage-volume-mounts)
- [n8n環境変数](https://docs.n8n.io/hosting/environment-variables/)

## 🤝 サポート

問題が発生した場合：
1. このREADMEのトラブルシューティングセクションを確認
2. Cloud Runログを確認
3. n8nコミュニティフォーラムで質問

---

**Happy Automating! 🎉**
