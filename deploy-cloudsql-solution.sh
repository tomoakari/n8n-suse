#!/bin/bash

# Cloud SQL対応デプロイスクリプト
# SQLite問題をCloud SQLで根本解決

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

# Cloud SQL設定
DB_INSTANCE="n8n-postgres"
DB_NAME="n8n"
DB_USER="n8n_user"
DB_PASSWORD="n8n_secure_password_$(date +%s)"

echo "🔧 Cloud SQL対応でSQLite問題を根本解決します..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: Cloud SQL API有効化 ===
echo "🗄️ Step 2: Cloud SQL APIを有効化中..."
gcloud services enable sqladmin.googleapis.com

# === Step 3: Cloud SQL インスタンス作成 ===
echo "🗄️ Step 3: Cloud SQLインスタンスを作成中..."

# 既存インスタンスをチェック
if ! gcloud sql instances describe $DB_INSTANCE &>/dev/null; then
    echo "新しいCloud SQLインスタンスを作成します..."
    gcloud sql instances create $DB_INSTANCE \
        --database-version=POSTGRES_14 \
        --tier=db-f1-micro \
        --region=$REGION \
        --storage-type=SSD \
        --storage-size=10GB \
        --availability-type=zonal
    
    # データベース作成
    gcloud sql databases create $DB_NAME --instance=$DB_INSTANCE
    
    # ユーザー作成
    gcloud sql users create $DB_USER \
        --instance=$DB_INSTANCE \
        --password=$DB_PASSWORD
    
    echo "✅ Cloud SQL設定完了！"
    echo "🔑 DB Password: $DB_PASSWORD"
else
    echo "既存のCloud SQLインスタンスを使用します"
    echo "⚠️  既存のパスワードを使用してください"
fi

# === Step 4: Cloud SQL対応Dockerfileを作成 ===
echo "🐳 Step 4: Cloud SQL対応イメージをビルド中..."

# Cloud SQL接続文字列を取得
CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE --format="value(connectionName)")

# Cloud SQL対応Dockerfileを作成
cat > Dockerfile.cloudsql << 'EOF'
FROM n8nio/n8n:latest

# CloudRun設定
ENV N8N_PORT=8080
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https

# Task Runners無効化
ENV N8N_RUNNERS_ENABLED=false

# PostgreSQL設定（SQLite問題回避）
ENV DB_TYPE=postgresdb
ENV DB_POSTGRESDB_PORT=5432
ENV DB_POSTGRESDB_DATABASE=n8n

# CloudRun向け設定
ENV N8N_SECURE_COOKIE=false
ENV N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true

# 基本設定
ENV N8N_METRICS=false
ENV N8N_LOG_LEVEL=info
ENV N8N_BASIC_AUTH_ACTIVE=false

# データディレクトリ作成
RUN mkdir -p /tmp/.n8n
ENV N8N_USER_FOLDER=/tmp/.n8n

# ポート公開
EXPOSE 8080

# nodeユーザーで実行
USER node
EOF

# Cloud SQL対応Dockerfileを使用
cp Dockerfile.cloudsql Dockerfile

echo "Cloud SQL対応設定でビルドします..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "✅ Cloud SQL対応イメージビルド完了！"

# === Step 5: CloudRunサービスデプロイ ===
echo "🚀 Step 5: Cloud SQL対応でサービスをデプロイ中..."

# Cloud SQL対応設定でサービス更新
gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8080 \
    --memory 1Gi \
    --cpu 1 \
    --timeout 3600 \
    --add-cloudsql-instances $CONNECTION_NAME \
    --set-env-vars N8N_PORT=8080 \
    --set-env-vars N8N_HOST=0.0.0.0 \
    --set-env-vars N8N_PROTOCOL=https \
    --set-env-vars N8N_RUNNERS_ENABLED=false \
    --set-env-vars DB_TYPE=postgresdb \
    --set-env-vars DB_POSTGRESDB_HOST=/cloudsql/$CONNECTION_NAME \
    --set-env-vars DB_POSTGRESDB_PORT=5432 \
    --set-env-vars DB_POSTGRESDB_DATABASE=$DB_NAME \
    --set-env-vars DB_POSTGRESDB_USER=$DB_USER \
    --set-env-vars DB_POSTGRESDB_PASSWORD=$DB_PASSWORD \
    --set-env-vars N8N_USER_FOLDER=/tmp/.n8n \
    --set-env-vars N8N_SECURE_COOKIE=false \
    --set-env-vars N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true \
    --set-env-vars N8N_METRICS=false \
    --set-env-vars N8N_LOG_LEVEL=info \
    --set-env-vars N8N_BASIC_AUTH_ACTIVE=false

# CloudRunのURLを取得
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")

echo "✅ Cloud SQL対応デプロイ完了！"
echo "🌐 n8n URL: $SERVICE_URL"

echo ""
echo "🔧 適用したCloud SQL設定："
echo "   ✅ PostgreSQL使用（SQLite問題完全回避）"
echo "   ✅ Cloud SQLインスタンス: $DB_INSTANCE"
echo "   ✅ データベース: $DB_NAME"
echo "   ✅ ユーザー: $DB_USER"
echo "   ✅ 接続名: $CONNECTION_NAME"
echo ""
echo "💾 データベース情報："
echo "   インスタンス: $DB_INSTANCE"
echo "   データベース: $DB_NAME"
echo "   ユーザー: $DB_USER"
if [ ! -z "$DB_PASSWORD" ]; then
    echo "   パスワード: $DB_PASSWORD"
fi
echo ""
echo "🎯 確認事項："
echo "1. $SERVICE_URL にアクセスしてn8nの画面を確認"
echo "2. SQLite MISUSE エラーが完全に解消されているか確認"
echo "3. PostgreSQLでのデータ永続化を確認"
echo ""
echo "📝 ログ確認コマンド："
echo "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME\" --limit 10 --project=$PROJECT_ID"
echo ""
echo "🎉 Cloud SQL対応による根本解決完了！"

# 一時ファイルを削除
rm -f Dockerfile.cloudsql
