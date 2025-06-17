#!/bin/bash

# n8n CloudRun デプロイスクリプト
# 設定を適切に変更してから実行してください

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
BUCKET_NAME="n8n-data-bucket"     # Cloud Storageバケット名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

# データベース設定（Cloud SQL使用時）
DB_INSTANCE="n8n-postgres"
DB_NAME="n8n"
DB_USER="n8n_user"

echo "🚀 n8n CloudRunデプロイを開始します..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: API有効化 ===
echo "🔧 Step 2: 必要なAPIを有効化中..."
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com

# === Step 3: Cloud Storageバケット作成 ===
echo "📦 Step 3: Cloud Storageバケットを作成中..."
gsutil mb -l $REGION gs://$BUCKET_NAME || echo "バケットが既に存在します"

# === Step 4: Dockerイメージビルド ===
echo "🐳 Step 4: Dockerイメージをビルド中..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

# === Step 5: Cloud SQL インスタンス作成（オプション） ===
echo "💾 Step 5: Cloud SQLインスタンスを作成中..."
read -p "Cloud SQLインスタンスを作成しますか？ (y/n): " create_db
if [ "$create_db" = "y" ]; then
    gcloud sql instances create $DB_INSTANCE \
        --database-version=POSTGRES_14 \
        --tier=db-f1-micro \
        --region=$REGION \
        --storage-type=SSD \
        --storage-size=10GB || echo "インスタンスが既に存在します"
    
    # データベース作成
    gcloud sql databases create $DB_NAME --instance=$DB_INSTANCE
    
    # ユーザー作成
    read -s -p "データベースパスワードを入力してください: " db_password
    echo
    gcloud sql users create $DB_USER --instance=$DB_INSTANCE --password=$db_password
fi

# === Step 6: 環境変数設定 ===
echo "⚙️ Step 6: 環境変数を設定中..."

# 暗号化キー生成
ENCRYPTION_KEY=$(openssl rand -hex 32)
echo "生成された暗号化キー: $ENCRYPTION_KEY"
echo "このキーを安全に保存してください！"

# Basic認証パスワード生成
BASIC_AUTH_PASSWORD=$(openssl rand -base64 12)
echo "Basic認証パスワード: $BASIC_AUTH_PASSWORD"

# === Step 7: CloudRunサービスデプロイ ===
echo "🚀 Step 7: CloudRunサービスをデプロイ中..."

# Cloud SQL接続文字列取得（Cloud SQL使用時）
if [ "$create_db" = "y" ]; then
    CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE --format="value(connectionName)")
    DB_HOST="/cloudsql/$CONNECTION_NAME"
else
    DB_HOST="localhost"  # SQLite使用時
fi

# CloudRunサービスデプロイ（パーミッション修正版）
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
    --set-env-vars N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true

# CloudRunのURLを取得
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")

echo "✅ デプロイ完了！"
echo "🌐 n8n URL: $SERVICE_URL"
echo "👤 ユーザー名: admin"
echo "🔑 パスワード: $BASIC_AUTH_PASSWORD"
echo "🔐 暗号化キー: $ENCRYPTION_KEY"
echo ""
echo "⚠️  重要: 暗号化キーとパスワードを安全に保存してください！"

# === Step 8: ボリュームマウント設定（Preview機能） ===
echo "📁 Step 8: Cloud Storageボリュームマウントの設定..."
echo "現在この機能はPreviewのため、Google Cloud Consoleから手動で設定してください:"
echo "1. Cloud Runコンソールでサービスを選択"
echo "2. 新しいリビジョンを編集"
echo "3. ボリュームタブでCloud Storage FUSEを選択"
echo "4. バケット名: $BUCKET_NAME"
echo "5. マウントパス: /home/node/.n8n"

echo ""
echo "🔧 パーミッション問題解決済み！"
echo "ℹ️  追加された設定："
echo "   - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true"
echo "   - N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true"
echo "   - 起動時パーミッション修正スクリプト"
echo ""
echo "🎉 セットアップが完了しました！"
