#!/usr/bin/env python3
"""
generate_posts.py
tasks.backlog.yaml を読み込み、Claude API で7日分のSNS投稿文を生成する

使い方:
  python scripts/generate_posts.py
"""

import base64
import os
import sys
import yaml
import anthropic
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
BACKLOG_PATH = PROJECT_ROOT / "docs" / "tasks.backlog.yaml"
SCREENSHOTS_DIR = PROJECT_ROOT / "docs" / "screenshots"
POSTS_DIR = PROJECT_ROOT / "posts"

# スクリーンショットは最大3枚まで添付（トークン節約）
MAX_SCREENSHOTS = 3


def load_env():
    """backend/.env から環境変数を読み込む"""
    env_path = PROJECT_ROOT / "backend" / ".env"
    if not env_path.exists():
        return
    with open(env_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, val = line.split("=", 1)
                os.environ.setdefault(key.strip(), val.strip())


def parse_backlog() -> list[dict]:
    """tasks.backlog.yaml を読み込む"""
    if not BACKLOG_PATH.exists():
        print(f"❌ {BACKLOG_PATH} が見つかりません")
        sys.exit(1)
    with open(BACKLOG_PATH, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data.get("tasks", [])


def select_tasks(tasks: list[dict]) -> list[dict]:
    """
    status:done かつ sns_auto:true のタスクから
    completed_at 降順で最大7件、同 area は最大2件まで選定
    """
    eligible = [
        t for t in tasks
        if t.get("status") == "done" and t.get("sns_auto") is True
    ]
    eligible.sort(key=lambda t: t.get("completed_at") or "", reverse=True)

    selected = []
    area_count: dict[str, int] = {}
    for task in eligible:
        area = task.get("area", "other")
        if area_count.get(area, 0) >= 2:
            continue
        selected.append(task)
        area_count[area] = area_count.get(area, 0) + 1
        if len(selected) >= 7:
            break
    return selected


def load_screenshot_b64(rel_path: str) -> str | None:
    """スクリーンショットを base64 エンコードして返す"""
    if not rel_path:
        return None
    full_path = PROJECT_ROOT / rel_path
    if not full_path.exists():
        return None
    with open(full_path, "rb") as f:
        return base64.standard_b64encode(f.read()).decode("utf-8")


def build_task_summary(tasks: list[dict]) -> str:
    """タスク情報をプロンプト用テキストに変換"""
    lines = []
    for i, t in enumerate(tasks, 1):
        lines.append(f"{i}. 【{t.get('area', '')}】{t['title']}")
        lines.append(f"   完了日: {t.get('completed_at', '不明')}")
        lines.append(f"   発信ヒント: {t.get('sns_hint') or 'なし'}")
        lines.append(f"   スクショ: {'あり' if t.get('screenshot_path') else 'なし'}")
        lines.append("")
    return "\n".join(lines)


def generate_posts(tasks: list[dict]) -> str:
    """Claude API で7日分の投稿文を生成"""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        print("❌ ANTHROPIC_API_KEY が設定されていません")
        sys.exit(1)

    today = date.today()
    task_summary = build_task_summary(tasks)

    # スクショ付きタスクを最大3件取得
    screenshot_tasks = [t for t in tasks if t.get("screenshot_path")][:MAX_SCREENSHOTS]

    # コンテンツブロック構築（画像→テキストの順）
    content_blocks: list[dict] = []
    for t in screenshot_tasks:
        img_b64 = load_screenshot_b64(t["screenshot_path"])
        if img_b64:
            content_blocks.append({
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": "image/png",
                    "data": img_b64,
                },
            })
            content_blocks.append({
                "type": "text",
                "text": f"↑ 上の画像は「{t['title']}」のスクリーンショットです。",
            })

    prompt = f"""あなたは「今」の辞書という個人開発アプリのSNS担当クリエイターです。
以下の実装タスクをもとに、7日分のSNS投稿文を生成してください。

## アプリについて
- 辞書的意味と「今の使われ方」を1画面に並べて見せる辞書アプリ
- AIが言葉の現代的な使われ方・誤用を解析する
- 日本語・英語の両方に対応
- デザインは墨・和紙・朱・金の日本伝統色ダークテーマ

## 完了した実装タスク（投稿素材）
{task_summary}

## 投稿構成ルール
- 7日分、それぞれ異なるテーマで生成する
- 内訳：言葉ネタ（誤用・意味の変化など）3〜4日、共感ネタ2日、進捗ネタ1〜2日
- Flutter・FastAPI・Supabase・Claude APIなどの技術用語は絶対に使わない
- 実装の話より「ユーザーが得られる体験・気づき」として書く
- スクショがあるタスクはその画面の雰囲気・内容を投稿文に反映する
- 本日の日付: {today}
- 投稿予定日 = タスクの completed_at + 2〜3日 を目安にする

## 出力フォーマット（このフォーマットを厳守）

---
## Day 1（YYYY-MM-DD）

### テーマ
言葉ネタ or 共感 or 進捗

### X投稿文
（140文字以内。ハッシュタグ含む。改行OK）

### Instagramキャプション
（200〜400文字。体験・気づきを丁寧に。最後にハッシュタグ5〜8個）

### TikTok台本
（30秒想定のセリフ形式。「〇〇秒：△△を見せながら〜」のように動作も記載）

### Buffer登録メモ
- 使用画像：（ファイル名 or 「なし」）
- 投稿日時：（YYYY-MM-DD 08:00 など）
- プラットフォーム：X / Instagram / TikTok

---

以上を Day 1 〜 Day 7 まで続けて出力してください。
"""

    content_blocks.append({"type": "text", "text": prompt})

    client = anthropic.Anthropic(api_key=api_key)
    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=8192,
        messages=[{"role": "user", "content": content_blocks}],
    )
    return message.content[0].text


def save_posts(content: str) -> Path:
    """生成内容を posts/YYYY-MM-DD/ に day1.md〜day7.md として保存"""
    today = date.today().isoformat()
    output_dir = POSTS_DIR / today
    output_dir.mkdir(parents=True, exist_ok=True)

    # "## Day " で分割
    parts = content.split("\n---\n")
    day_parts = [p for p in parts if p.strip().startswith("## Day")]

    for i, part in enumerate(day_parts, 1):
        filepath = output_dir / f"day{i}.md"
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(part.strip() + "\n")
        print(f"  ✅ day{i}.md")

    # 全文も保存
    all_path = output_dir / "all_posts.md"
    with open(all_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  ✅ all_posts.md（全文）")

    return output_dir


def main():
    print("\n📱 SNS投稿文生成スクリプト")
    print("=" * 40)

    load_env()

    print("\n1️⃣  タスクバックログを読み込み中...")
    tasks = parse_backlog()
    print(f"   全タスク: {len(tasks)}件")

    print("\n2️⃣  投稿対象タスクを選定中...")
    selected = select_tasks(tasks)
    print(f"   選定タスク: {len(selected)}件")
    for t in selected:
        has_ss = "📸" if t.get("screenshot_path") else "  "
        print(f"   {has_ss} {t['title']}")

    print("\n3️⃣  Claude APIで投稿文を生成中（少し時間がかかります）...")
    content = generate_posts(selected)

    print("\n4️⃣  ファイルに保存中...")
    output_dir = save_posts(content)

    today = date.today().isoformat()
    print(f"\n✅ 完了！ posts/{today}/ に保存しました")
    print(f"   → {output_dir}/all_posts.md で全文確認できます")


if __name__ == "__main__":
    main()
