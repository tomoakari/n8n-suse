#!/bin/bash

# 最新n8n対応修復デプロイスクリプト
# Task Runners設定とその他最新設定を適用

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

echo "🔧 最新n8n設定でCannot GET /エラーを修復します..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: 最新n8n対応Dockerfileを作成 ===
echo "🐳 Step 2: 最新n8n対応イメージをビルド中..."

# 最新設定Dockerfileを作成
cat > Dockerfile.latest << 'EOF'
FROM n8nio/n8n:latest

# CloudRun基本設定
ENV N8N_PORT=8080
ENV N8N_HOST=0.0.0.0

# プロトコル設定
ENV N8N_PROTOCOL=https

# Task Runners設定（新バージョン対応）
ENV N8N_RUNNERS_ENABLED=true

# 基本設定
ENV N8N_METRICS=true
ENV N8N_LOG_LEVEL=info

# セキュリティ設定
ENV N8N_SECURE_COOKIE=false
ENV N8N_BASIC_AUTH_ACTIVE=false

# ポート公開
EXPOSE 8080
EOF

# 最新版Dockerfileを使用
cp Dockerfile.latest Dockerfile

echo "最新n8n設定でビルドします..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "✅ 最新版イメージビルド完了！"

# === Step 3: サービス更新デプロイ ===
echo "🚀 Step 3: 最新設定でサービスを更新中..."

# 最新設定でサービス更新
gcloud run services update $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
    --region $REGION \
    --platform managed \
    --port 8080 \
    --memory 2Gi \
    --cpu 1 \
    --timeout 3600 \
    --set-env-vars N8N_PORT=8080 \
    --set-env-vars N8N_HOST=0.0.0.0 \
    --set-env-vars N8N_PROTOCOL=https \
    --set-env-vars N8N_RUNNERS_ENABLED=true \
    --set-env-vars N8N_METRICS=true \
    --set-env-vars N8N_LOG_LEVEL=info \
    --set-env-vars N8N_SECURE_COOKIE=false \
    --set-env-vars N8N_BASIC_AUTH_ACTIVE=false

# CloudRunのURLを取得
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")

echo "✅ 最新設定更新完了！"
echo "🌐 n8n URL: $SERVICE_URL"

echo ""
echo "🔧 適用した最新設定："
echo "   ✅ N8N_RUNNERS_ENABLED=true (Task Runners有効化)"
echo "   ✅ N8N_SECURE_COOKIE=false (CloudRun対応)"
echo "   ✅ N8N_BASIC_AUTH_ACTIVE=false (一時的に認証無効)"
echo "   ✅ 最新のn8nバージョン対応"
echo ""
echo "🎯 確認事項："
echo "1. $SERVICE_URL にアクセスしてn8nの画面を確認"
echo "2. 動作確認後、必要に応じてBasic認証を再有効化"
echo "3. Task Runners警告メッセージが消えることを確認"
echo ""
echo "📝 ログ確認コマンド："
echo "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME\" --limit 10 --project=$PROJECT_ID"
echo ""
echo "🎉 最新n8n対応修復完了！"

# 一時ファイルを削除
rm -f Dockerfile.latest
