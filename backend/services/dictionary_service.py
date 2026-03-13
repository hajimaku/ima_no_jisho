"""
外部辞書APIから辞書的意味を取得する
- 日本語: goo辞書API (GOO_APP_ID 環境変数が必要)
- 英語: Free Dictionary API (キー不要)
- 取得失敗時は None を返し、呼び出し元でAI生成にフォールバック
"""
import os
import re
import httpx


def _is_japanese(word: str) -> bool:
    return bool(re.search(r'[\u3040-\u9fff]', word))


async def fetch_dict_meaning(word: str) -> dict | None:
    """
    辞書的意味を外部APIから取得する。
    返却: {"dict_meaning": str, "dict_example": str, "reading": str} or None
    """
    if _is_japanese(word):
        return await _fetch_japanese(word)
    else:
        return await _fetch_english(word)


async def _fetch_english(word: str) -> dict | None:
    """Free Dictionary API (https://dictionaryapi.dev)"""
    url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{word}"
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(url)
        if resp.status_code != 200:
            return None

        data = resp.json()
        entry = data[0]

        # 発音記号
        phonetics = entry.get("phonetics", [])
        reading = next((p.get("text", "") for p in phonetics if p.get("text")), "")

        # 最初の品詞・定義・用例を取得
        meanings = entry.get("meanings", [])
        if not meanings:
            return None

        first_meaning = meanings[0]
        definitions = first_meaning.get("definitions", [])
        if not definitions:
            return None

        dict_meaning = definitions[0].get("definition", "")
        dict_example = definitions[0].get("example", "")

        return {
            "reading": reading,
            "dict_meaning": dict_meaning,
            "dict_example": dict_example,
        }
    except Exception:
        return None


async def _fetch_japanese(word: str) -> dict | None:
    """goo辞書API (https://labs.goo.ne.jp/)"""
    app_id = os.getenv("GOO_APP_ID")
    if not app_id:
        return None  # APIキー未設定 → AIにフォールバック

    url = "https://labs.goo.ne.jp/api/dictionary"
    payload = {
        "app_id": app_id,
        "title": word,
        "body": word,
    }
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.post(url, json=payload)
        if resp.status_code != 200:
            return None

        data = resp.json()
        # goo辞書APIのレスポンス: {"title": "...", "candidates": [...]}
        candidates = data.get("candidates", [])
        if not candidates:
            return None

        best = candidates[0]
        dict_meaning = best.get("body", "")
        if not dict_meaning:
            return None

        return {
            "reading": best.get("reading", ""),
            "dict_meaning": dict_meaning,
            "dict_example": "",
        }
    except Exception:
        return None
