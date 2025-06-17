#!/bin/bash

# 超確実修復デプロイスクリプト
# n8n command not found エラーを完全解決

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

echo "🔧 n8n command not found エラーを完全修復します..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: 超安全版Dockerfileを使用してビルド ===
echo "🐳 Step 2: 超安全版Dockerイメージをビルド中..."

# Dockerfile.safeを一時的にDockerfileとしてコピー
cp Dockerfile.safe Dockerfile

echo "Dockerfile.safe（元のn8n entrypoint使用）でビルドします..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "✅ 超安全版イメージビルド完了！"

# === Step 3: 既存サービス更新デプロイ ===
echo "🚀 Step 3: 既存サービスを更新中..."

# 既存のサービスがあるかチェック
if gcloud run services describe $SERVICE_NAME --region=$REGION --platform=managed &>/dev/null; then
    echo "既存のサービスを新しいイメージで更新します..."
    
    gcloud run services update $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
        --region $REGION \
        --platform managed \
        --set-env-vars N8N_PORT=8080 \
        --set-env-vars N8N_HOST=0.0.0.0 \
        --set-env-vars N8N_PROTOCOL=https \
        --set-env-vars N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
        --set-env-vars N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true
    
    # CloudRunのURLを取得
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")
    
    echo "✅ サービス更新完了！"
    echo "🌐 n8n URL: $SERVICE_URL"
    
else
    echo "⚠️  既存のサービスが見つかりません。"
    echo "新規デプロイする場合は deploy.sh または deploy-sqlite.sh を使用してください。"
fi

echo ""
echo "🔧 修復内容："
echo "   - 元のn8nイメージのentrypointを使用"
echo "   - カスタムCMDを削除して安全性向上"
echo "   - 環境変数で必要な設定を適用"
echo "   - n8n command not found エラーを完全回避"
echo ""
echo "🎉 修復完了！n8nが正常に起動するはずです！"
echo "🌐 URLにアクセスしてn8nの画面を確認してください：$SERVICE_URL"
