import json
import os
from datetime import date as date_type
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import anthropic

router = APIRouter()


class DailyWordResponse(BaseModel):
    date: str
    title: str
    body: str
    related_words: list[str]


# 日付ごとのキャッシュ（プロセス内）
_cache: dict[str, DailyWordResponse] = {}


async def _generate_daily_word(date_str: str) -> DailyWordResponse:
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise ValueError("ANTHROPIC_API_KEY が設定されていません")

    client = anthropic.AsyncAnthropic(api_key=api_key)

    system = "あなたは日本語の言葉の意味を解説する専門家です。必ずJSON形式のみで回答し、マークダウンや説明文は含めないでください。"
    user = f"""
今日の日付: {date_str}

日本語の誤用されやすい言葉または現代で意味が変わりつつある言葉を1つ選び、以下のJSON形式で返してください。
毎回違う言葉を選んでください（日付をシードに使ってください）。

{{
  "title": "「言葉」の本当の意味",
  "body": "本来の意味と現代での使われ方の違いを2〜3文で説明。",
  "related_words": ["関連語1", "関連語2", "関連語3"]
}}
"""

    message = await client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=512,
        temperature=0.2,
        system=system,
        messages=[{"role": "user", "content": user}],
    )

    raw = message.content[0].text.strip()
    if raw.startswith("```"):
        lines = raw.split("\n")
        raw = "\n".join(lines[1:-1])

    data = json.loads(raw)
    return DailyWordResponse(
        date=date_str,
        title=data["title"],
        body=data["body"],
        related_words=data.get("related_words", []),
    )


@router.get("/daily-word", response_model=DailyWordResponse)
async def get_daily_word():
    today = str(date_type.today())
    if today not in _cache:
        try:
            _cache[today] = await _generate_daily_word(today)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"今日の一言の生成に失敗しました: {str(e)}")
    return _cache[today]


@router.get("/daily-word/{date}", response_model=DailyWordResponse)
async def get_daily_word_by_date(date: str):
    if date not in _cache:
        try:
            _cache[date] = await _generate_daily_word(date)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"今日の一言の生成に失敗しました: {str(e)}")
    return _cache[date]
