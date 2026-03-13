"""
外部辞書APIから辞書的意味を取得する
- 日本語: Wikipedia API（日本語版、キー不要）
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
        }
    except Exception:
        return None


async def _fetch_japanese(word: str) -> dict | None:
    """Wikipedia API（日本語版）
    概念語・名詞に強い。基本動詞など項目がない場合はNoneを返してAIにフォールバック。
    """
    import urllib.parse
    encoded = urllib.parse.quote(word)
    url = f"https://ja.wikipedia.org/api/rest_v1/page/summary/{encoded}"
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(url, headers={"Accept": "application/json"})
        if resp.status_code != 200:
            return None

        data = resp.json()

        # disambiguationページ（曖昧さ回避）はスキップ
        if data.get("type") == "disambiguation":
            return None

        extract = data.get("extract", "").strip()
        if not extract:
            return None

        # extractが長すぎる場合は最初の2文に絞る
        sentences = extract.split("。")
        short_extract = "。".join(sentences[:2]) + "。" if len(sentences) > 2 else extract

        return {
            "reading": "",  # Wikipedia APIでは読み仮名が取れないのでAIに委ねる
            "dict_meaning": short_extract,
            "dict_example": "",
        }
    except Exception:
        return None
