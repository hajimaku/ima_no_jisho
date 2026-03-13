import os
from supabase import create_client, Client

_client: Client | None = None


def get_client() -> Client:
    global _client
    if _client is None:
        url = os.getenv("SUPABASE_URL")
        # service_role key があればそちらを優先（バックエンド専用、RLS/権限不要）
        key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_ANON_KEY")
        if not url or not key:
            raise ValueError("SUPABASE_URL / SUPABASE_ANON_KEY が設定されていません")
        _client = create_client(url, key)
    return _client


async def log_search(word: str, user_id: str) -> None:
    """search_logs テーブルに記録"""
    client = get_client()
    client.table("search_logs").insert({
        "word": word,
        "user_id": user_id,
    }).execute()


async def log_daily_word(date: str, user_id: str) -> None:
    """daily_word_logs テーブルに記録"""
    client = get_client()
    client.table("daily_word_logs").insert({
        "date": date,
        "user_id": user_id,
    }).execute()


def get_daily_word(date: str) -> dict | None:
    """daily_words テーブルから指定日の一言を取得"""
    try:
        client = get_client()
        res = client.table("daily_words").select("*").eq("date", date).limit(1).execute()
        if res.data:
            return res.data[0]
        return None
    except Exception:
        return None


def save_daily_word(date: str, title: str, body: str, related_words: list[str]) -> None:
    """daily_words テーブルに保存（同日は上書きしない）"""
    try:
        client = get_client()
        client.table("daily_words").upsert({
            "date": date,
            "title": title,
            "body": body,
            "related_words": related_words,
        }, on_conflict="date").execute()
    except Exception:
        pass  # 保存失敗してもレスポンスは返す


def get_past_word_titles(limit: int = 30) -> list[str]:
    """直近 limit 件の使用済みタイトルを取得（重複防止用）"""
    try:
        client = get_client()
        res = (
            client.table("daily_words")
            .select("title")
            .order("date", desc=True)
            .limit(limit)
            .execute()
        )
        return [row["title"] for row in res.data]
    except Exception:
        return []
