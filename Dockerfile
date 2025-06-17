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

# パーミッション修正スクリプトを直接作成
RUN cat > /home/node/fix-permissions.sh << 'EOF'
#!/bin/bash

# n8n起動前のパーミッション修正スクリプト
echo "🔧 n8n起動前の設定を開始..."

# n8nデータディレクトリの確認と作成
if [ ! -d "/home/node/.n8n" ]; then
    echo "📁 .n8nディレクトリを作成中..."
    mkdir -p /home/node/.n8n
fi

# Cloud Storage FUSEマウントの場合、設定ファイルの権限を修正
echo "🔐 設定ファイルの権限を修正中..."

# 設定ファイルが存在する場合、権限を修正
if [ -f "/home/node/.n8n/config" ]; then
    echo "📄 config ファイルの権限を修正..."
    chmod 600 /home/node/.n8n/config 2>/dev/null || echo "権限変更をスキップ（Cloud Storage FUSE）"
fi

# データベースファイルの権限修正
if [ -f "/home/node/.n8n/database.sqlite" ]; then
    echo "🗄️ database.sqlite ファイルの権限を修正..."
    chmod 600 /home/node/.n8n/database.sqlite 2>/dev/null || echo "権限変更をスキップ（Cloud Storage FUSE）"
fi

# ディレクトリ全体の権限確認
echo "📂 ディレクトリ権限を確認中..."
chmod 700 /home/node/.n8n 2>/dev/null || echo "ディレクトリ権限変更をスキップ（Cloud Storage FUSE）"

# n8nが必要とする他のディレクトリも確認
mkdir -p /home/node/.n8n/nodes
mkdir -p /home/node/.n8n/credentials
chmod -R 700 /home/node/.n8n 2>/dev/null || echo "再帰的権限変更をスキップ（Cloud Storage FUSE）"

echo "✅ 権限設定完了！n8nを起動します..."

# n8nを起動
exec n8n
EOF

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
