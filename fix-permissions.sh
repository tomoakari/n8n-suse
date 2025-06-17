#!/bin/bash

# n8n起動前のパーミッション修正スクリプト
# Cloud Storage FUSEでのパーミッション問題を解決

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
