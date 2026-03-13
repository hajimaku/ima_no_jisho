import json
import os
import anthropic

SYSTEM_PROMPT = """
あなたは日本語・英語の言葉の意味を解説する専門家です。
必ずJSON形式のみで回答し、マークダウンや説明文は含めないでください。
"""

# 辞書的意味が取得できなかった場合: 全フィールドをAIで生成
USER_PROMPT_FULL = """
以下の単語について、必ず下記JSON形式で返してください。

単語: {word}

{{
  "reading": "読み仮名（英語の場合は発音記号またはカタカナ読み）",
  "pos": "品詞（名詞/動詞/形容詞など）",
  "dict_meaning": "辞書的・本来の意味（1〜2文）",
  "dict_example": "辞書的意味での用例",
  "modern_meaning": "現代での実際の使われ方（1〜2文）",
  "modern_example": "現代的な用例",
  "caution": "誤用・注意点があれば記載。なければnull",
  "usage_ratio": "現代での誤用率の目安（例：約70%）。不明ならnull",
  "related_words": ["関連語1", "関連語2", "関連語3"]
}}

「related_words」は以下の基準で3語を選んでください。
- 1語：直接関連する言葉（類義語・対義語・派生語など）
- 1語：同じ文脈・場面でよく使われる言葉
- 1語：少し意外だが連想が広がる言葉（読者が「え、これも？」となるもの）
"""

# 辞書的意味が取得済みの場合: 現代用法のみAIで生成
USER_PROMPT_MODERN_ONLY = """
以下の単語について、必ず下記JSON形式で返してください。
辞書的意味はすでに取得済みのため、現代での使われ方・注意点・関連語のみ生成してください。

単語: {word}
辞書的意味（参考）: {dict_meaning}

{{
  "pos": "品詞（名詞/動詞/形容詞など）",
  "modern_meaning": "現代での実際の使われ方（1〜2文）",
  "modern_example": "現代的な用例",
  "caution": "誤用・注意点があれば記載。なければnull",
  "usage_ratio": "現代での誤用率の目安（例：約70%）。不明ならnull",
  "related_words": ["関連語1", "関連語2", "関連語3"]
}}

「related_words」は以下の基準で3語を選んでください。
- 1語：直接関連する言葉（類義語・対義語・派生語など）
- 1語：同じ文脈・場面でよく使われる言葉
- 1語：少し意外だが連想が広がる言葉（読者が「え、これも？」となるもの）
"""


async def analyze_word(word: str, dict_data: dict | None = None) -> dict:
    """Claude APIを使って単語を解析する（非同期）"""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise ValueError("ANTHROPIC_API_KEY が設定されていません")

    client = anthropic.AsyncAnthropic(api_key=api_key)

    if dict_data and dict_data.get("dict_meaning"):
        prompt = USER_PROMPT_MODERN_ONLY.format(
            word=word,
            dict_meaning=dict_data["dict_meaning"],
        )
    else:
        prompt = USER_PROMPT_FULL.format(word=word)

    message = await client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        temperature=0.2,
        system=SYSTEM_PROMPT.strip(),
        messages=[{"role": "user", "content": prompt}],
    )

    raw = message.content[0].text.strip()

    if raw.startswith("```"):
        lines = raw.split("\n")
        raw = "\n".join(lines[1:-1])

    result = json.loads(raw)

    # 辞書APIから取得したフィールドをマージ
    if dict_data:
        if dict_data.get("reading"):
            result.setdefault("reading", dict_data["reading"])
        if dict_data.get("dict_meaning"):
            result["dict_meaning"] = dict_data["dict_meaning"]
        if dict_data.get("dict_example"):
            result["dict_example"] = dict_data["dict_example"]
        result["dict_source"] = dict_data.get("dict_source", "AI解析")
    else:
        result["dict_source"] = "AI解析"

    return result
