# n8n CloudRun デプロイメントガイド 🚀

このプロジェクトでは、n8nワークフローオートメーションツールをGoogle Cloud Runにデプロイする方法を提供します。

## 📋 前提条件

- Google Cloud Platform アカウント
- gcloud CLI インストール済み
- Docker インストール済み
- 適切なGCP権限（Cloud Run、Cloud Build、Cloud Storage）

## 🏗️ アーキテクチャ

### フルスタック版（PostgreSQL + Cloud Storage）
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloud Run     │    │  Cloud Storage  │    │   Cloud SQL     │
│   (n8n App)    │────│   (File Data)   │    │  (Workflows)    │
│                 │    │                 │    │   PostgreSQL    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### シンプル版（SQLite + Cloud Storage）
```
┌─────────────────┐    ┌─────────────────┐
│   Cloud Run     │    │  Cloud Storage  │
│   (n8n App)    │────│  (SQLite + Files)│
│                 │    │                 │
└─────────────────┘    └─────────────────┘
```

## 🚀 クイックスタート

### 🗄️ オプション1: SQLite版（推奨：シンプル）

小〜中規模の利用に最適！シンプルで管理が楽 😊

```bash
# リポジトリをクローン
git clone https://github.com/tomoakari/n8n-suse.git
cd n8n-suse

# SQLite専用デプロイスクリプトを使用
vim deploy-sqlite.sh  # PROJECT_IDなどを設定
chmod +x deploy-sqlite.sh
./deploy-sqlite.sh
```

### 🐘 オプション2: PostgreSQL版（本番環境推奨）

大規模利用や高可用性が必要な場合

```bash
# 通常のデプロイスクリプトを使用
vim deploy.sh  # PROJECT_IDなどを設定
chmod +x deploy.sh
./deploy.sh
# Cloud SQLインスタンス作成で "y" を選択
```

## 📁 ファイル構成

```
n8n-suse/
├── Dockerfile                      # n8n用カスタムDockerfile
├── cloudrun-service.yaml           # CloudRunサービス定義（PostgreSQL版）
├── cloudrun-service-sqlite.yaml    # CloudRunサービス定義（SQLite版）
├── deploy.sh                       # 自動デプロイスクリプト（選択式）
├── deploy-sqlite.sh                # SQLite専用デプロイスクリプト
├── fix-permissions.sh              # パーミッション修正スクリプト
└── README.md                       # このファイル
```

## ⚙️ データベース比較

| 項目 | SQLite版 | PostgreSQL版 |
|------|----------|---------------|
| **セットアップ** | 🟢 超簡単 | 🟡 やや複雑 |
| **コスト** | 🟢 安い | 🟡 中程度 |
| **パフォーマンス** | 🟡 小〜中規模 | 🟢 高性能 |
| **同時接続** | 🟡 制限あり | 🟢 高い |
| **バックアップ** | 🟡 手動 | 🟢 自動 |
| **スケーラビリティ** | 🟡 制限あり | 🟢 高い |
| **推奨用途** | 個人・小チーム | 企業・本番環境 |

## 🗄️ SQLite版の特徴

### ✅ メリット
- **シンプル**: Cloud SQL不要でセットアップ簡単
- **コスト削減**: PostgreSQLインスタンス料金不要
- **管理楽**: データベース管理なし
- **十分な性能**: 小〜中規模なら問題なし

### ⚠️ 制限事項
- 同時書き込み制限あり
- 非常に大きなデータセットには不向き
- 手動バックアップ推奨

### 💾 データ保存場所
```
Cloud Storage Bucket:
└── .n8n/
    ├── database.sqlite    # ワークフロー・設定データ
    ├── config            # n8n設定ファイル
    └── nodes/            # カスタムノード
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
3. **SQLiteのバックアップ**: 定期的にCloud Storageバケットのバックアップを取ってください
4. **スケール判断**: 同時ユーザーが多い場合はPostgreSQL版を検討してください

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

**3. SQLiteファイルが見つからない**
```bash
# Cloud Storageバケット内を確認
gsutil ls gs://your-bucket-name/.n8n/
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

SQLite版の場合は `cloudrun-service-sqlite.yaml` を編集：

```yaml
env:
- name: CUSTOM_VAR
  value: "custom_value"
```

### リソース調整

```yaml
# SQLite版は軽量設定
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi
```

## 🆕 最新の更新

- ✅ **SQLite専用デプロイオプション追加**
- ✅ Cloud Storage FUSE パーミッション問題の自動修正
- ✅ CloudRun 互換性の向上
- ✅ 起動時パーミッション修正スクリプト追加
- ✅ Webhook 登録解除問題の修正
- ✅ SQLite最適化設定

## 💡 どちらを選ぶべき？

### SQLite版を選ぶべき場合 🗄️
- 個人利用や小チーム（〜10人）
- ワークフロー数が少ない（〜100個）
- シンプルさを重視
- コスト削減重視
- 学習・テスト用途

### PostgreSQL版を選ぶべき場合 🐘
- 企業や大チーム（10人以上）
- 大量のワークフロー（100個以上）
- 高可用性が必要
- 同時実行が多い
- 本番環境での安定運用

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
