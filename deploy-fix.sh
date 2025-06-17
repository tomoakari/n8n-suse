#!/bin/bash

# クイック修復デプロイスクリプト
# fix-permissions.sh エラーを解決してすぐにデプロイ

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

echo "🔧 fix-permissions.sh エラーを修復してデプロイします..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: 修正版Dockerイメージビルド ===
echo "🐳 Step 2: 修正版Dockerイメージをビルド中..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "✅ 修正版イメージビルド完了！"

# === Step 3: 既存サービス更新デプロイ ===
echo "🚀 Step 3: 既存サービスを更新中..."

# 既存のサービスがあるかチェック
if gcloud run services describe $SERVICE_NAME --region=$REGION --platform=managed &>/dev/null; then
    echo "既存のサービスを新しいイメージで更新します..."
    
    gcloud run services update $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$IMAGE_NAME \
        --region $REGION \
        --platform managed
    
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
echo "   - fix-permissions.sh スクリプトをDockerfile内に埋め込み"
echo "   - 外部ファイル依存を解消"
echo "   - 同じパーミッション修正機能を維持"
echo ""
echo "🎉 修復完了！n8nが正常に起動するはずです！"
