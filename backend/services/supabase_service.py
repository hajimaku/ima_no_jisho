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
