# 「今」の辞書 — CLAUDE.md

Claude Codeがこのプロジェクトで作業する際の全体方針。迷ったときは必ずここに立ち返ること。

---

## アプリの目的

辞書的意味と「今の使われ方」をAIで並列表示する日本語・英語辞書アプリ。

従来の辞書アプリは「編集者が事前に書いた意味」を表示するだけ。このアプリは
**「辞書に書いてある意味」と「今こう使われている意味」を同じ画面に並べる**のが最大の差別化。

---

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| モバイル | Flutter 3.x（iOS / Android 同時対応） |
| 状態管理 | Riverpod |
| バックエンド | FastAPI（Python） |
| データベース | Supabase（PostgreSQL） |
| キャッシュ | flutter_cache_manager |
| AI | Claude API（claude-sonnet-4-6） |
| 辞書データ | goo辞書API（日本語MVP） |
| ローカルDB | Hive（検索履歴・お気に入り） |
| 通知 | firebase_messaging |

---

## ディレクトリ構成

```
ima_no_jisho/
  ├── CLAUDE.md                    ← このファイル
  ├── docs/
  │   └── tasks.backlog.yaml       ← SNS発信用タスク管理
  ├── lib/
  │   ├── main.dart
  │   ├── app/
  │   │   ├── router.dart          # GoRouter 画面遷移
  │   │   └── theme.dart           # カラー・フォント定義
  │   ├── features/
  │   │   ├── search/              # S-02, S-03
  │   │   │   ├── search_screen.dart
  │   │   │   ├── result_screen.dart
  │   │   │   └── search_provider.dart
  │   │   ├── daily_word/          # S-04
  │   │   └── calendar/            # S-05
  │   └── shared/
  │       ├── widgets/             # 共通UI部品
  │       └── api/                 # APIクライアント
  └── backend/
      ├── main.py
      ├── routers/
      │   └── search.py
      └── services/
          └── ai_service.py
```

---

## 画面構成

| 画面ID | 画面名 | 役割 |
|--------|--------|------|
| S-02 | ホーム（検索） | 検索バー + 今日の一言カード + 最近の検索 |
| S-03 | 検索結果 | 辞書的意味 / 今の意味 の並列表示（最重要画面） |
| S-04 | 今日の一言 詳細 | 一言の全文 + 解説 + 関連単語 |
| S-05 | カレンダー履歴 | 閲覧日の記録 + 過去の一言を日付で振り返り |

画面遷移の詳細は `ima_no_jisho_ui_design.docx` を参照。

---

## デザイン原則

```dart
// theme.dart に必ず定義すること
backgroundColor: Color(0xFF0A0A14),   // 墨
cardColor:       Color(0xFF12121F),   // カード背景
washiColor:      Color(0xFFF5F0E8),   // メインテキスト（和紙）
vermillion:      Color(0xFFE84A2F),   // アクセント（朱）＝今の意味
gold:            Color(0xFFC9A84C),   // 今日の一言
indigo:          Color(0xFF3D5A8A),   // 辞書的意味
```

- フォント：見出しに `Noto Serif JP`、本文に `Noto Sans JP`
- 「辞書的意味」と「今の意味」は**背景色・ラベル色を必ず変えて視覚的に分離**する
- 辞書的意味ブロック背景：`#0D1520`（青みがかった暗色）
- 今の意味ブロック背景：`#1A0A08`（赤みがかった暗色）

---

## 重要な設計方針

### AI生成について
- 辞書的定義は**辞書APIから取得**する。AIで生成しない
- 「今の使われ方」のみAIで生成する
- AI生成コンテンツには必ず `[AI解析]` ラベルを表示する（省略禁止）
- Claude APIの `temperature` は `0.2` 以下に設定する（出力の揺れを防ぐ）

### キャッシュ
- 同一単語の検索結果は**24時間キャッシュ**する（APIコスト削減）
- 「今日の一言」は日付が変わるまでキャッシュする

### エラー処理
- AI生成中はスケルトンUIを表示、完了後フェードイン（0.25s）
- タイムアウト：5秒。エラー時は再試行ボタンを表示

---

## やってはいけないこと

- `[AI解析]` ラベルを省略する
- 辞書的意味をAIで生成する（必ず辞書APIから取得）
- 「辞書的意味」と「今の意味」を同じデザインで表示する（必ず視覚的に分離）
- Flutter固有名詞（AWS / FastAPI / Supabase など）をUI上に表示する
- `temperature` を `0.3` 以上に設定する

---

## APIエンドポイント

| エンドポイント | 説明 |
|--------------|------|
| `POST /api/search` | 単語検索。キャッシュ優先、なければAI生成 |
| `GET /api/daily-word` | 今日の一言（日付ベースで固定） |
| `GET /api/daily-word/{date}` | 特定日の一言（カレンダー用） |
| `POST /api/log` | ユーザーの起動・閲覧ログ記録 |

---

## AIプロンプトテンプレート（ai_service.py）

```python
SYSTEM = """
あなたは日本語・英語の言葉の意味を解説する専門家です。
必ずJSON形式のみで回答し、マークダウンや説明文は含めないでください。
"""

USER = f"""
以下の単語について、必ず下記JSON形式で返してください。

単語: {word}

{{
  "reading": "読み仮名",
  "pos": "品詞（名詞/動詞/形容詞など）",
  "dict_meaning": "辞書的・本来の意味（1〜2文）",
  "dict_example": "辞書的意味での用例",
  "modern_meaning": "現代での実際の使われ方（1〜2文）",
  "modern_example": "現代的な用例",
  "caution": "誤用・注意点があれば記載。なければnull",
  "usage_ratio": "現代での誤用率の目安（例：約70%）。不明ならnull"
}}
"""
```

---

## 実装優先順位

1. `theme.dart`（色・フォント定義）
2. GoRouterでルーティング設定
3. S-02 ホーム画面UI
4. FastAPI + Claude API連携
5. S-03 検索結果画面（並列表示）
6. S-04 今日の一言画面
7. Supabase認証・ログ記録
8. S-05 カレンダー履歴画面

---

## SNS発信との連携

### タスク完了時のルール（必ず実行すること）

実装タスクが完了したら、**その場で** `docs/tasks.backlog.yaml` を更新する。

```yaml
status: done
sns_auto: true
completed_at: "2026-03-09"  # 完了した実際の日付（currentDateを使う）
sns_hint: "どんな体験として発信するかのヒント（ユーザー目線で書く）"
```

### 更新のタイミング
- 画面UI実装完了時
- APIエンドポイント動作確認時
- フロント↔バックエンド接続完了時
- 新機能が動作確認できた時

### スクリーンショットの自動保存
Playwright MCPが使える状態のとき、画面実装完了後に自動でスクリーンショットを撮り
`docs/screenshots/YYYY-MM-DD/` に保存する。

### SNS投稿生成
週1回 Claude.ai で「今の辞書の投稿作って」と呼び出すと、
`docs/tasks.backlog.yaml` の `sns_auto: true` かつ `status: done` のタスクをもとに
投稿文が自動生成される。
