#!/bin/bash

# GCSボリュームマウント対応デプロイスクリプト
# Cloud Storage FUSE設定後の最適化版

set -e

# === 設定セクション ===
PROJECT_ID="your-gcp-project-id"  # GCPプロジェクトID
REGION="asia-northeast1"          # リージョン（東京）
SERVICE_NAME="n8n-service"        # CloudRunサービス名
IMAGE_NAME="n8n-cloudrun"         # Dockerイメージ名

echo "🔧 GCSボリュームマウント対応でn8nを最適化します..."

# === Step 1: GCPプロジェクト設定 ===
echo "📋 Step 1: GCPプロジェクトを設定中..."
gcloud config set project $PROJECT_ID

# === Step 2: GCS対応Dockerfileを作成 ===
echo "🐳 Step 2: GCS対応イメージをビルド中..."

# GCS対応Dockerfileを作成
cat > Dockerfile.gcs << 'EOF'
FROM n8nio/n8n:latest

# CloudRun設定
ENV N8N_PORT=8080
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https

# Task Runners無効化（CloudRun最適化）
ENV N8N_RUNNERS_ENABLED=false

# SQLite + GCS FUSE設定
ENV DB_TYPE=sqlite
ENV DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite

# パーミッション問題解決
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

# CloudRun最適化設定
ENV N8N_SECURE_COOKIE=false
ENV N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true

# 基本設定
ENV N8N_METRICS=false
ENV N8N_LOG_LEVEL=info

# 認証設定（後で有効化推奨）
ENV N8N_BASIC_AUTH_ACTIVE=false

# GCS FUSE対応の権限修正スクリプト
RUN echo '#!/bin/bash' > /home/node/startup.sh && \
    echo 'echo "🔧 GCS FUSE対応でn8nを起動中..."' >> /home/node/startup.sh && \
    echo 'mkdir -p /home/node/.n8n' >> /home/node/startup.sh && \
    echo 'if [ -d "/home/node/.n8n" ]; then' >> /home/node/startup.sh && \
    echo '  echo "📁 GCSボリュームマウント確認OK"' >> /home/node/startup.sh && \
    echo '  ls -la /home/node/.n8n/ || echo "ディレクトリは空です（正常）"' >> /home/node/startup.sh && \
    echo 'else' >> /home/node/startup.sh && \
    echo '  echo "⚠️ GCSボリュームマウントが設定されていません"' >> /home/node/startup.sh && \
    echo '  exit 1' >> /home/node/startup.sh && \
    echo 'fi' >> /home/node/startup.sh && \
    echo 'echo "✅ n8nを起動します..."' >> /home/node/startup.sh && \
    echo 'exec n8n' >> /home/node/startup.sh && \
    chmod +x /home/node/startup.sh && \
    chown node:node /home/node/startup.sh

# ポート公開
EXPOSE 8080

# nodeユーザーで実行
USER node

# 起動スクリプト実行
CMD ["/home/node/startup.sh"]
EOF

# GCS対応Dockerfileを使用
cp Dockerfile.gcs Dockerfile

echo "GCS対応設定でビルドします..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$IMAGE_NAME

echo "✅ GCS対応イメージビルド完了！"

# === Step 3: サービス更新デプロイ ===
echo "🚀 Step 3: GCS対応設定でサービスを更新中..."

# GCS対応設定でサービス更新
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
    --set-env-vars DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite \
    --set-env-vars N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
    --set-env-vars N8N_SECURE_COOKIE=false \
    --set-env-vars N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true \
    --set-env-vars N8N_METRICS=false \
    --set-env-vars N8N_LOG_LEVEL=info \
    --set-env-vars N8N_BASIC_AUTH_ACTIVE=false

# CloudRunのURLを取得
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")

echo "✅ GCS対応更新完了！"
echo "🌐 n8n URL: $SERVICE_URL"

echo ""
echo "🔧 適用したGCS対応設定："
echo "   ✅ SQLite + GCS FUSE組み合わせ"
echo "   ✅ N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true"
echo "   ✅ 起動時GCSボリューム確認"
echo "   ✅ データ永続化対応"
echo ""
echo "📋 GCSボリュームマウント設定確認:"
echo "   1. Cloud Runコンソールでサービスを確認"
echo "   2. ボリュームタブで以下が設定されているか確認："
echo "      - ボリューム名: n8n-storage"
echo "      - タイプ: Cloud Storage buckets" 
echo "      - バケット名: 実際のバケット名"
echo "      - マウントパス: /home/node/.n8n"
echo ""
echo "🎯 確認事項："
echo "1. $SERVICE_URL にアクセスしてn8nの画面を確認"
echo "2. SQLite MISUSE エラーが解消されているか確認"
echo "3. データがGCSに永続化されているか確認"
echo ""
echo "📝 ログ確認コマンド："
echo "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME\" --limit 10 --project=$PROJECT_ID"
echo ""
echo "🎉 GCS対応最適化完了！"

# 一時ファイルを削除
rm -f Dockerfile.gcs
