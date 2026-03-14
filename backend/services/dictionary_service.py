"""
外部辞書APIから辞書的意味を取得する
- 日本語: Wiktionary日本語版（MediaWiki API、キー不要）
- 英語: Free Dictionary API（キー不要）
- 取得失敗時は None を返し、呼び出し元でAI生成にフォールバック
"""
import re
import urllib.parse
import httpx

_WIKTIONARY_HEADERS = {"User-Agent": "ImaNoJisho/1.0 (https://imanojisho.vercel.app)"}


def _is_japanese(word: str) -> bool:
    return bool(re.search(r'[\u3040-\u9fff]', word))


async def fetch_dict_meaning(word: str) -> dict | None:
    if _is_japanese(word):
        return await _fetch_japanese(word)
    else:
        return await _fetch_english(word)


def _parse_wikitext_definition(content: str) -> str | None:
    """wikitextから最初の定義（# で始まる行）を抽出してプレーンテキスト化する"""
    for line in content.splitlines():
        line = line.strip()
        # #* (例文) #: (補足) ## (サブ定義) は除外。# で始まる定義行のみ対象
        if not line.startswith("#"):
            continue
        if len(line) < 2 or line[1] in ("#", "*", ":"):
            continue

        text = line[1:].strip()

        # {{ruby|BASE|READING}} → BASE
        text = re.sub(r'\{\{ruby\|([^|}\n]+)\|[^}]+\}\}', r'\1', text)

        # 残りの {{テンプレート}} を除去
        text = re.sub(r'\{\{[^}]*\}\}', '', text)

        # [[リンク|表示]] → 表示
        text = re.sub(r'\[\[[^\]]*\|([^\]]+)\]\]', r'\1', text)

        # [[リンク]] → リンク
        text = re.sub(r'\[\[([^\]]+)\]\]', r'\1', text)

        # '''太字''' ''斜体'' → テキスト
        text = re.sub(r"'{2,3}", '', text)

        # 参考文献部分（括弧内の長い出典）を除去
        text = re.sub(r'（[^）]{20,}）', '', text)

        text = text.strip()
        if len(text) > 10:
            return text

    return None


async def _fetch_wiktionary_content(word: str, client: httpx.AsyncClient) -> str | None:
    """Wiktionaryからwikitext本文を取得する（1ページ分）"""
    encoded = urllib.parse.quote(word)
    url = (
        f"https://ja.wiktionary.org/w/api.php"
        f"?action=query&titles={encoded}&prop=revisions"
        f"&rvslots=main&rvprop=content&format=json&formatversion=2"
    )
    resp = await client.get(url, headers=_WIKTIONARY_HEADERS)
    if resp.status_code != 200:
        return None
    pages = resp.json().get("query", {}).get("pages", [])
    if not pages or pages[0].get("missing"):
        return None
    return pages[0].get("revisions", [{}])[0].get("slots", {}).get("main", {}).get("content", "")


async def _fetch_japanese(word: str) -> dict | None:
    """Wiktionary日本語版 MediaWiki API（参照先リダイレクト・表記ゆれ対応）"""
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            content = await _fetch_wiktionary_content(word, client)

            # 「〇〇」参照 形式の場合は参照先を取得
            if content:
                ref_match = re.search(r'「\[\[([^\]]+)\]\]」参照', content)
                if ref_match:
                    content = await _fetch_wiktionary_content(ref_match.group(1), client)

            # ひらがな表記でリトライ（「情けは人のためならず」→「情けは人の為ならず」は変換困難なため省略）
            if not content:
                return None

            definition = _parse_wikitext_definition(content)
            if not definition:
                return None

            return {
                "reading": "",
                "dict_meaning": definition,
                "dict_example": "",
                "dict_source": "Wiktionary",
            }
    except Exception:
        return None


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
