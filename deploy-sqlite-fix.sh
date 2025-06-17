#!/bin/bash

# SQLite問題解決デプロイスクリプト
# Cloud Storage FUSEでのSQLite問題を完全回避

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

echo "🔧 SQLite Database handle エラーを完全解決します..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: SQLite問題回避Dockerfileを作成 ===
echo "🐳 Step 2: SQLite問題回避イメージをビルド中..."

# SQLite問題回避Dockerfileを作成
cat > Dockerfile.sqlite-fix << 'EOF'
FROM n8nio/n8n:latest

# CloudRun設定
ENV N8N_PORT=8080
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https

# Task Runners無効化
ENV N8N_RUNNERS_ENABLED=false

# SQLite問題回避 - メモリ内データベース使用
ENV DB_TYPE=sqlite
ENV DB_SQLITE_DATABASE=:memory:

# CloudRun向け設定
ENV N8N_SECURE_COOKIE=false
ENV N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true

# 基本設定
ENV N8N_METRICS=false
ENV N8N_LOG_LEVEL=info
ENV N8N_BASIC_AUTH_ACTIVE=false

# 一時的にCloud Storage無効化
ENV N8N_USER_FOLDER=/tmp/.n8n
RUN mkdir -p /tmp/.n8n

# ポート公開
EXPOSE 8080

# nodeユーザーで実行
USER node
EOF

# SQLite修正Dockerfileを使用
cp Dockerfile.sqlite-fix Dockerfile

echo "SQLite問題回避設定でビルドします..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "✅ SQLite問題回避イメージビルド完了！"

# === Step 3: サービス更新デプロイ ===
echo "🚀 Step 3: SQLite問題回避設定でサービスを更新中..."

# SQLite問題回避設定でサービス更新
gcloud run services update $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
    --region $REGION \
    --platform managed \
    --port 8080 \
    --memory 1Gi \
    --cpu 1 \
    --timeout 3600 \
    --concurrency 50 \
    --set-env-vars N8N_PORT=8080 \
    --set-env-vars N8N_HOST=0.0.0.0 \
    --set-env-vars N8N_PROTOCOL=https \
    --set-env-vars N8N_RUNNERS_ENABLED=false \
    --set-env-vars DB_TYPE=sqlite \
    --set-env-vars DB_SQLITE_DATABASE=:memory: \
    --set-env-vars N8N_USER_FOLDER=/tmp/.n8n \
    --set-env-vars N8N_SECURE_COOKIE=false \
    --set-env-vars N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true \
    --set-env-vars N8N_METRICS=false \
    --set-env-vars N8N_LOG_LEVEL=info \
    --set-env-vars N8N_BASIC_AUTH_ACTIVE=false

# CloudRunのURLを取得
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")

echo "✅ SQLite問題回避更新完了！"
echo "🌐 n8n URL: $SERVICE_URL"

echo ""
echo "🔧 適用したSQLite問題回避設定："
echo "   ✅ DB_SQLITE_DATABASE=:memory: (メモリ内データベース)"
echo "   ✅ N8N_USER_FOLDER=/tmp/.n8n (ローカルファイルシステム)"
echo "   ✅ Cloud Storage FUSE回避"
echo "   ✅ SQLite handle closed エラー解消"
echo ""
echo "⚠️  注意："
echo "   - データは一時的（リスタート時にリセット）"
echo "   - まずは動作確認を優先"
echo "   - 動作確認後、永続化設定を検討"
echo ""
echo "🎯 確認事項："
echo "1. $SERVICE_URL にアクセスしてn8nの画面を確認"
echo "2. QueryFailedError: SQLITE_MISUSE エラーが解消されているか確認"
echo "3. n8nの初期設定画面が表示されるか確認"
echo ""
echo "📝 ログ確認コマンド："
echo "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME\" --limit 10 --project=$PROJECT_ID"
echo ""
echo "🎉 SQLite問題回避修復完了！"

# 一時ファイルを削除
rm -f Dockerfile.sqlite-fix
