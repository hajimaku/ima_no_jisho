import json
import os
import anthropic

SYSTEM_PROMPT = """
あなたは日本語・英語の言葉の意味を解説する専門家です。
必ずJSON形式のみで回答し、マークダウンや説明文は含めないでください。
"""

USER_PROMPT_TEMPLATE = """
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


async def analyze_word(word: str) -> dict:
    """Claude APIを使って単語を解析する（非同期）"""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise ValueError("ANTHROPIC_API_KEY が設定されていません")

    # AsyncAnthropicで非同期実行（FastAPIのevent loopをブロックしない）
    client = anthropic.AsyncAnthropic(api_key=api_key)

    message = await client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        temperature=0.2,
        system=SYSTEM_PROMPT.strip(),
        messages=[
            {
                "role": "user",
                "content": USER_PROMPT_TEMPLATE.format(word=word),
            }
        ],
    )

    raw = message.content[0].text.strip()

    # ```json ... ``` ブロックが返ってきた場合を除去
    if raw.startswith("```"):
        lines = raw.split("\n")
        raw = "\n".join(lines[1:-1])

    return json.loads(raw)
