import json
import os
from datetime import date as date_type
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import anthropic
from services.supabase_service import (
    get_daily_word,
    save_daily_word,
    get_past_word_titles,
)

router = APIRouter()


class DailyWordResponse(BaseModel):
    date: str
    title: str
    body: str
    related_words: list[str]


# インメモリキャッシュ（Supabaseへのリクエストを減らす）
_cache: dict[str, DailyWordResponse] = {}


async def _generate_daily_word(date_str: str) -> DailyWordResponse:
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise ValueError("ANTHROPIC_API_KEY が設定されていません")

    # 過去に使った言葉を取得して重複を防ぐ
    past_titles = get_past_word_titles(limit=60)
    past_list = "\n".join(f"- {t}" for t in past_titles) if past_titles else "（なし）"

    client = anthropic.AsyncAnthropic(api_key=api_key)

    system = "あなたは日本語の言葉の意味を解説する専門家です。必ずJSON形式のみで回答し、マークダウンや説明文は含めないでください。"
    user = f"""
今日の日付: {date_str}

日本語の誤用されやすい言葉または現代で意味が変わりつつある言葉を1つ選び、以下のJSON形式で返してください。

【重要】以下の言葉はすでに使用済みです。絶対に選ばないでください：
{past_list}

選び方のヒント（バリエーションを出すため）:
- 慣用句・ことわざの誤用（例：情けは人のためならず、役不足など）
- カタカナ語の誤解（例：アイデンティティ、コンセンサスなど）
- 若者言葉や新語の意味変化
- 敬語・謙譲語の誤用
- 同音異義語の混同
- 漢字の多義的用法

{{
  "title": "「言葉」の本当の意味",
  "body": "本来の意味と現代での使われ方の違いを2〜3文で説明。",
  "related_words": ["関連語1", "関連語2", "関連語3"]
}}
"""

    message = await client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=512,
        temperature=0.9,
        system=system,
        messages=[{"role": "user", "content": user}],
    )

    raw = message.content[0].text.strip()
    if raw.startswith("```"):
        lines = raw.split("\n")
        raw = "\n".join(lines[1:-1])

    data = json.loads(raw)
    response = DailyWordResponse(
        date=date_str,
        title=data["title"],
        body=data["body"],
        related_words=data.get("related_words", []),
    )

    # Supabaseに永続保存
    save_daily_word(
        date=date_str,
        title=response.title,
        body=response.body,
        related_words=response.related_words,
    )

    return response


async def _get_or_generate(date_str: str) -> DailyWordResponse:
    # 1. インメモリキャッシュ確認
    if date_str in _cache:
        return _cache[date_str]

    # 2. Supabaseから取得
    row = get_daily_word(date_str)
    if row:
        result = DailyWordResponse(
            date=row["date"],
            title=row["title"],
            body=row["body"],
            related_words=row.get("related_words") or [],
        )
        _cache[date_str] = result
        return result

    # 3. AIで生成してSupabaseに保存
    result = await _generate_daily_word(date_str)
    _cache[date_str] = result
    return result


@router.get("/daily-word", response_model=DailyWordResponse)
async def get_daily_word_today():
    today = str(date_type.today())
    try:
        return await _get_or_generate(today)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"今日の一言の生成に失敗しました: {str(e)}")


@router.get("/daily-word/{date}", response_model=DailyWordResponse)
async def get_daily_word_by_date(date: str):
    try:
        return await _get_or_generate(date)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"今日の一言の生成に失敗しました: {str(e)}")
