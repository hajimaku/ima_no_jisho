#!/bin/bash
# capture_and_update.sh
# スクリーンショット撮影 → backlog更新 を一発実行するスクリプト
#
# 使い方:
#   ./scripts/capture_and_update.sh
#   ./scripts/capture_and_update.sh --date 2026-03-10
#   ./scripts/capture_and_update.sh --port 3000

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NODE="/usr/local/opt/node@20/bin/node"
PYTHON="/usr/local/bin/python3.13"

# 引数を解析
DATE=""
PORT="3000"
while [[ $# -gt 0 ]]; do
  case $1 in
    --date) DATE="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo "========================================"
echo "  「今」の辞書 — スクショ & backlog更新"
echo "========================================"

# Flutter Web サーバーが起動しているか確認
if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:${PORT}" | grep -q "200"; then
  echo ""
  echo ""
  echo "❌ http://localhost:${PORT} に接続できません"
  echo "   先に Flutter Web を起動してください:"
  echo "   node /tmp/spa_server.js &"
  echo ""
  exit 1
fi

echo ""
echo "1️⃣  Playwright でスクリーンショット撮影..."
cd "$PROJECT_ROOT"

# 引数を個別に渡す
NODE_ARGS=""
[[ -n "$DATE" ]] && NODE_ARGS="$NODE_ARGS --date $DATE"
[[ -n "$PORT" ]] && NODE_ARGS="$NODE_ARGS --port $PORT"
$NODE scripts/capture_screenshots.js $NODE_ARGS

echo ""
echo "2️⃣  tasks.backlog.yaml を更新..."
$PYTHON scripts/update_backlog.py

echo ""
echo "========================================"
echo "  ✅ 完了！"
echo "========================================"
