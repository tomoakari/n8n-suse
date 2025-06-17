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

# ヘルスチェック用エンドポイント
ENV N8N_METRICS=true

# CloudRun用の起動設定
EXPOSE 8080

# 権限設定
USER node

# n8n設定ファイルの権限を起動時に修正するスクリプト
COPY --chown=node:node fix-permissions.sh /home/node/fix-permissions.sh
RUN chmod +x /home/node/fix-permissions.sh

# 起動コマンドを修正版スクリプト経由に変更
CMD ["/home/node/fix-permissions.sh"]
