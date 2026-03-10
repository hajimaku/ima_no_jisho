from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.supabase_service import log_search, log_daily_word

router = APIRouter()


class SearchLogRequest(BaseModel):
    word: str
    user_id: str


class DailyWordLogRequest(BaseModel):
    date: str
    user_id: str


@router.post("/log/search", status_code=204)
async def post_search_log(request: SearchLogRequest):
    try:
        await log_search(request.word, request.user_id)
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ログ記録に失敗しました: {str(e)}")


@router.post("/log/daily-word", status_code=204)
async def post_daily_word_log(request: DailyWordLogRequest):
    try:
        await log_daily_word(request.date, request.user_id)
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ログ記録に失敗しました: {str(e)}")
