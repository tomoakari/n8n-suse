# n8n CloudRun用カスタムDockerfile
FROM n8nio/n8n:latest

# CloudRunはポート8080を使用
ENV N8N_PORT=8080
ENV N8N_HOST=0.0.0.0

# CloudRunで必要な環境変数
ENV N8N_PROTOCOL=https
ENV N8N_EDITOR_BASE_URL=""
ENV N8N_LOG_LEVEL=info

# データディレクトリの作成
RUN mkdir -p /home/node/.n8n

# ヘルスチェック用エンドポイント
ENV N8N_METRICS=true

# CloudRun用の起動設定
EXPOSE 8080

# 権限設定
USER node

# 起動コマンド
CMD ["n8n"]
