#!/bin/bash

# CloudRun最適化修復デプロイスクリプト
# Task Runners無効版でシンプル動作を目指す

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

echo "🔧 CloudRun最適化でCannot GET /エラーを修復します..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: CloudRun最適化Dockerfileを作成 ===
echo "🐳 Step 2: CloudRun最適化イメージをビルド中..."

# CloudRun最適化Dockerfileを作成
cat > Dockerfile.cloudrun << 'EOF'
FROM n8nio/n8n:latest

# CloudRun最適化設定
ENV N8N_PORT=8080
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https

# Task Runners無効化（CloudRunでは問題を起こす可能性）
ENV N8N_RUNNERS_ENABLED=false

# CloudRun向け設定
ENV N8N_SECURE_COOKIE=false
ENV N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true

# 基本機能のみ有効
ENV N8N_METRICS=false
ENV N8N_LOG_LEVEL=warn
ENV N8N_BASIC_AUTH_ACTIVE=false

# ディレクトリ作成
RUN mkdir -p /home/node/.n8n

# ポート公開
EXPOSE 8080

# nodeユーザーで実行
USER node
EOF

# CloudRun最適化Dockerfileを使用
cp Dockerfile.cloudrun Dockerfile

echo "CloudRun最適化設定でビルドします..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "✅ CloudRun最適化イメージビルド完了！"

# === Step 3: サービス更新デプロイ ===
echo "🚀 Step 3: CloudRun最適化設定でサービスを更新中..."

# CloudRun最適化設定でサービス更新
gcloud run services update $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
    --region $REGION \
    --platform managed \
    --port 8080 \
    --memory 1Gi \
    --cpu 1 \
    --timeout 3600 \
    --concurrency 100 \
    --set-env-vars N8N_PORT=8080 \
    --set-env-vars N8N_HOST=0.0.0.0 \
    --set-env-vars N8N_PROTOCOL=https \
    --set-env-vars N8N_RUNNERS_ENABLED=false \
    --set-env-vars N8N_SECURE_COOKIE=false \
    --set-env-vars N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true \
    --set-env-vars N8N_METRICS=false \
    --set-env-vars N8N_LOG_LEVEL=warn \
    --set-env-vars N8N_BASIC_AUTH_ACTIVE=false

# CloudRunのURLを取得
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")

echo "✅ CloudRun最適化更新完了！"
echo "🌐 n8n URL: $SERVICE_URL"

echo ""
echo "🔧 適用したCloudRun最適化設定："
echo "   ✅ N8N_RUNNERS_ENABLED=false (Task Runners無効 - CloudRun最適化)"
echo "   ✅ N8N_SECURE_COOKIE=false (CloudRun対応)"
echo "   ✅ N8N_METRICS=false (軽量化)"
echo "   ✅ N8N_LOG_LEVEL=warn (ログ最小化)"
echo "   ✅ 認証無効化（デバッグ用）"
echo "   ✅ メモリ1Gi、同時実行100（CloudRun最適化）"
echo ""
echo "🎯 確認事項："
echo "1. $SERVICE_URL にアクセスしてn8nの画面を確認"
echo "2. Welcome to n8nまたは初期設定画面が表示されるか確認"
echo "3. Cannot GET / エラーが解消されているか確認"
echo ""
echo "📝 ログ確認コマンド："
echo "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME\" --limit 10 --project=$PROJECT_ID"
echo ""
echo "🎉 CloudRun最適化修復完了！"

# 一時ファイルを削除
rm -f Dockerfile.cloudrun
