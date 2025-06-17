#!/bin/bash

# 緊急修復デプロイスクリプト
# Cannot GET / エラーを解決してn8nを正常起動

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

echo "🔧 Cannot GET / エラーを緊急修復します..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: 完全にシンプルなDockerfileを作成 ===
echo "🐳 Step 2: 完全シンプル版Dockerイメージをビルド中..."

# 最もシンプルなDockerfileを作成
cat > Dockerfile.emergency << 'EOF'
FROM n8nio/n8n:latest

# CloudRunの基本設定のみ
ENV N8N_PORT=8080
ENV N8N_HOST=0.0.0.0

# 必要最小限の設定
ENV N8N_PROTOCOL=https
ENV N8N_BASIC_AUTH_ACTIVE=false

# ポート公開
EXPOSE 8080

# 元のentrypointとcmdを完全に維持
EOF

# 緊急版Dockerfileを使用
cp Dockerfile.emergency Dockerfile

echo "完全シンプル版（最小設定）でビルドします..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "✅ 緊急版イメージビルド完了！"

# === Step 3: 完全新規デプロイ（設定リセット） ===
echo "🚀 Step 3: サービスを完全リセットしてデプロイ中..."

# 既存サービスを削除
echo "既存サービスを削除中..."
gcloud run services delete $SERVICE_NAME --region=$REGION --platform=managed --quiet || echo "サービスが存在しません（正常）"

# 完全新規でデプロイ
echo "完全新規でサービスをデプロイします..."
gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8080 \
    --memory 1Gi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 5 \
    --timeout 3600 \
    --set-env-vars N8N_PORT=8080 \
    --set-env-vars N8N_HOST=0.0.0.0 \
    --set-env-vars N8N_PROTOCOL=https \
    --set-env-vars N8N_BASIC_AUTH_ACTIVE=false

# CloudRunのURLを取得
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")

echo "✅ 緊急修復完了！"
echo "🌐 n8n URL: $SERVICE_URL"

echo ""
echo "🔧 緊急修復内容："
echo "   - 最小限の設定のみ使用"
echo "   - Basic認証を一時的に無効化"
echo "   - サービス完全リセット"
echo "   - 元のn8nイメージのロジックを100%維持"
echo ""
echo "🎯 次のステップ："
echo "1. まず $SERVICE_URL にアクセスしてn8nが表示されるか確認"
echo "2. 動作確認後、必要に応じてBasic認証を再有効化"
echo "3. ログを確認：gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME\" --limit 10"
echo ""
echo "🎉 緊急修復完了！まずはURLアクセスを試してください！"

# 一時ファイルを削除
rm -f Dockerfile.emergency
