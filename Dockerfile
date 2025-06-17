# n8n CloudRun用カスタムDockerfile
FROM n8nio/n8n:latest

# CloudRunはポート8080を使用
ENV N8N_PORT=8080
ENV N8N_HOST=0.0.0.0

# CloudRunで必要な環境変数
ENV N8N_PROTOCOL=https
ENV N8N_EDITOR_BASE_URL=""
ENV N8N_LOG_LEVEL=info

# パーミッション警告を解決する環境変数
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

# Cloud Storage FUSE用の追加設定
ENV N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true

# データディレクトリの作成と権限設定
RUN mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node/.n8n && \
    chmod 700 /home/node/.n8n

# パーミッション修正スクリプトを作成
RUN echo '#!/bin/bash' > /home/node/fix-permissions.sh && \
    echo 'echo "🔧 n8n起動前の設定を開始..."' >> /home/node/fix-permissions.sh && \
    echo 'if [ ! -d "/home/node/.n8n" ]; then' >> /home/node/fix-permissions.sh && \
    echo '  echo "📁 .n8nディレクトリを作成中..."' >> /home/node/fix-permissions.sh && \
    echo '  mkdir -p /home/node/.n8n' >> /home/node/fix-permissions.sh && \
    echo 'fi' >> /home/node/fix-permissions.sh && \
    echo 'echo "🔐 設定ファイルの権限を修正中..."' >> /home/node/fix-permissions.sh && \
    echo 'if [ -f "/home/node/.n8n/config" ]; then' >> /home/node/fix-permissions.sh && \
    echo '  echo "📄 config ファイルの権限を修正..."' >> /home/node/fix-permissions.sh && \
    echo '  chmod 600 /home/node/.n8n/config 2>/dev/null || echo "権限変更をスキップ（Cloud Storage FUSE）"' >> /home/node/fix-permissions.sh && \
    echo 'fi' >> /home/node/fix-permissions.sh && \
    echo 'if [ -f "/home/node/.n8n/database.sqlite" ]; then' >> /home/node/fix-permissions.sh && \
    echo '  echo "🗄️ database.sqlite ファイルの権限を修正..."' >> /home/node/fix-permissions.sh && \
    echo '  chmod 600 /home/node/.n8n/database.sqlite 2>/dev/null || echo "権限変更をスキップ（Cloud Storage FUSE）"' >> /home/node/fix-permissions.sh && \
    echo 'fi' >> /home/node/fix-permissions.sh && \
    echo 'echo "📂 ディレクトリ権限を確認中..."' >> /home/node/fix-permissions.sh && \
    echo 'chmod 700 /home/node/.n8n 2>/dev/null || echo "ディレクトリ権限変更をスキップ（Cloud Storage FUSE）"' >> /home/node/fix-permissions.sh && \
    echo 'mkdir -p /home/node/.n8n/nodes' >> /home/node/fix-permissions.sh && \
    echo 'mkdir -p /home/node/.n8n/credentials' >> /home/node/fix-permissions.sh && \
    echo 'chmod -R 700 /home/node/.n8n 2>/dev/null || echo "再帰的権限変更をスキップ（Cloud Storage FUSE）"' >> /home/node/fix-permissions.sh && \
    echo 'echo "✅ 権限設定完了！n8nを起動します..."' >> /home/node/fix-permissions.sh && \
    echo 'exec n8n' >> /home/node/fix-permissions.sh

# スクリプトに実行権限を付与し、所有者を設定
RUN chmod +x /home/node/fix-permissions.sh && \
    chown node:node /home/node/fix-permissions.sh

# ヘルスチェック用エンドポイント
ENV N8N_METRICS=true

# CloudRun用の起動設定
EXPOSE 8080

# 権限設定
USER node

# 起動コマンドを修正版スクリプト経由に変更
CMD ["/home/node/fix-permissions.sh"]
