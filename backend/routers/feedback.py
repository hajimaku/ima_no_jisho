from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.supabase_service import save_feedback

router = APIRouter()

_VALID_REPORT_TYPES = [
    "辞書的意味が誤っている",
    "今の使われ方が誤っている",
    "用例が不適切",
    "その他",
]


class FeedbackRequest(BaseModel):
    word: str
    report_type: str
    user_id: str = ""


@router.post("/feedback")
async def post_feedback(request: FeedbackRequest):
    if not request.word.strip():
        raise HTTPException(status_code=400, detail="単語を入力してください")
    if request.report_type not in _VALID_REPORT_TYPES:
        raise HTTPException(status_code=400, detail="不正な報告種別です")

    save_feedback(
        word=request.word.strip(),
        report_type=request.report_type,
        user_id=request.user_id or "",
    )
    return {"status": "ok"}
