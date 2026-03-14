"""
外部辞書APIから辞書的意味を取得する
- 日本語: AI生成（Wikipedia APIはこのアプリの対象語に対応していないため除外）
- 英語: Free Dictionary API（キー不要）
- 取得失敗時は None を返し、呼び出し元でAI生成にフォールバック
"""
import re
import httpx


def _is_japanese(word: str) -> bool:
    return bool(re.search(r'[\u3040-\u9fff]', word))


async def fetch_dict_meaning(word: str) -> dict | None:
    """
    辞書的意味を外部APIから取得する。
    日本語は None を返してAI生成に委ねる。
    英語は Free Dictionary API を使用する。
    """
    if _is_japanese(word):
        return None  # 日本語はAIが辞書的意味も生成する
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

        phonetics = entry.get("phonetics", [])
        reading = next((p.get("text", "") for p in phonetics if p.get("text")), "")

        meanings = entry.get("meanings", [])
        if not meanings:
            return None

        definitions = meanings[0].get("definitions", [])
        if not definitions:
            return None

        dict_meaning = definitions[0].get("definition", "")
        dict_example = definitions[0].get("example", "")

        return {
            "reading": reading,
            "dict_meaning": dict_meaning,
            "dict_example": dict_example,
            "dict_source": "辞書API",
        }
    except Exception:
        return None
