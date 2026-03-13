import time
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.ai_service import analyze_word
from services.dictionary_service import fetch_dict_meaning

router = APIRouter()

# 単語 → (SearchResponse, 取得時刻) のインメモリキャッシュ
_cache: dict[str, tuple] = {}
_CACHE_TTL = 60 * 60 * 24  # 24時間


class SearchRequest(BaseModel):
    word: str


class SearchResponse(BaseModel):
    word: str
    reading: str
    pos: str
    dict_meaning: str
    dict_example: str
    modern_meaning: str
    modern_example: str
    caution: str | None
    usage_ratio: str | None
    related_words: list[str] = []
    dict_source: str = "AI解析"


@router.post("/search", response_model=SearchResponse)
async def search(request: SearchRequest):
    word = request.word.strip()
    if not word:
        raise HTTPException(status_code=400, detail="単語を入力してください")
    if len(word) > 100:
        raise HTTPException(status_code=400, detail="単語が長すぎます")

    # キャッシュヒット確認
    key = word.lower()
    if key in _cache:
        cached_response, cached_at = _cache[key]
        if time.time() - cached_at < _CACHE_TTL:
            return cached_response

    try:
        # 1. 外部辞書APIから辞書的意味を取得（失敗時はNone）
        dict_data = await fetch_dict_meaning(word)
        # 2. AIで現代用法を生成（辞書データがあれば渡す）
        result = await analyze_word(word, dict_data=dict_data)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI解析に失敗しました: {str(e)}")

    response = SearchResponse(
        word=word,
        reading=result.get("reading", ""),
        pos=result.get("pos", ""),
        dict_meaning=result.get("dict_meaning", ""),
        dict_example=result.get("dict_example", ""),
        modern_meaning=result.get("modern_meaning", ""),
        modern_example=result.get("modern_example", ""),
        caution=result.get("caution"),
        usage_ratio=result.get("usage_ratio"),
        related_words=result.get("related_words", []),
        dict_source=result.get("dict_source", "AI解析"),
    )
    _cache[key] = (response, time.time())
    return response
