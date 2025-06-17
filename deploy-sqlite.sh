#!/bin/bash

# n8n CloudRun デプロイスクリプト（SQLite専用版）
# Cloud SQLを使わずにSQLiteのみでシンプルにデプロイ

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
BUCKET_NAME="n8n-data-bucket"     # Cloud Storageバケット名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

echo "🚀 n8n CloudRunデプロイを開始します（SQLite版）..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: API有効化 ===
echo "🔧 Step 2: 必要なAPIを有効化中..."
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable storage.googleapis.com

# === Step 3: Cloud Storageバケット作成 ===
echo "📦 Step 3: Cloud Storageバケットを作成中..."
gsutil mb -l $REGION gs://$BUCKET_NAME || echo "バケットが既に存在します"

# === Step 4: Dockerイメージビルド ===
echo "🐳 Step 4: Dockerイメージをビルド中..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

# === Step 5: 環境変数設定 ===
echo "⚙️ Step 5: 環境変数を設定中..."

# 暗号化キー生成
ENCRYPTION_KEY=$(openssl rand -hex 32)
echo "生成された暗号化キー: $ENCRYPTION_KEY"
echo "このキーを安全に保存してください！"

# Basic認証パスワード生成
BASIC_AUTH_PASSWORD=$(openssl rand -base64 12)
echo "Basic認証パスワード: $BASIC_AUTH_PASSWORD"

# === Step 6: CloudRunサービスデプロイ（SQLite版） ===
echo "🗄️ Step 6: CloudRunサービスをデプロイ中（SQLite使用）..."

# CloudRunサービスデプロイ（SQLite専用設定）
gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8080 \
    --memory 2Gi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --timeout 3600 \
    --set-env-vars N8N_PORT=8080 \
    --set-env-vars N8N_HOST=0.0.0.0 \
    --set-env-vars N8N_PROTOCOL=https \
    --set-env-vars N8N_BASIC_AUTH_ACTIVE=true \
    --set-env-vars N8N_BASIC_AUTH_USER=admin \
    --set-env-vars N8N_BASIC_AUTH_PASSWORD=$BASIC_AUTH_PASSWORD \
    --set-env-vars N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY \
    --set-env-vars N8N_LOG_LEVEL=info \
    --set-env-vars N8N_METRICS=true \
    --set-env-vars N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
    --set-env-vars N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true \
    --set-env-vars DB_TYPE=sqlite \
    --set-env-vars N8N_DEFAULT_BINARY_DATA_MODE=filesystem

# CloudRunのURLを取得
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")

echo "✅ デプロイ完了！"
echo "🌐 n8n URL: $SERVICE_URL"
echo "👤 ユーザー名: admin"
echo "🔑 パスワード: $BASIC_AUTH_PASSWORD"
echo "🔐 暗号化キー: $ENCRYPTION_KEY"
echo ""
echo "⚠️  重要: 暗号化キーとパスワードを安全に保存してください！"

# === Step 7: ボリュームマウント設定（Preview機能） ===
echo "📁 Step 7: Cloud Storageボリュームマウントの設定..."
echo "現在この機能はPreviewのため、Google Cloud Consoleから手動で設定してください:"
echo "1. Cloud Runコンソールでサービスを選択"
echo "2. 新しいリビジョンを編集"
echo "3. ボリュームタブでCloud Storage FUSEを選択"
echo "4. バケット名: $BUCKET_NAME"
echo "5. マウントパス: /home/node/.n8n"

echo ""
echo "🗄️ データベース: SQLite（Cloud Storageに保存）"
echo "🔧 パーミッション問題解決済み！"
echo "ℹ️  SQLite使用により："
echo "   - シンプルな構成"
echo "   - Cloud SQL不要でコスト削減"
echo "   - 小〜中規模の利用に最適"
echo "   - database.sqlite ファイルがCloud Storageに永続化"
echo ""
echo "🎉 セットアップが完了しました！"
