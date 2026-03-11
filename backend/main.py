from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from routers import search, daily_word, log

load_dotenv()

app = FastAPI(
    title="今の辞書 API",
    description="辞書的意味と今の使われ方をAIで並列表示する辞書API",
    version="1.0.0",
)

import os
import logging

# 本番ではCORS_ORIGINSを環境変数で追加可能
_extra_origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
_origins = ["http://localhost:3000", "http://localhost:8080"] + _extra_origins
logging.warning(f"CORS origins: {_origins}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(search.router, prefix="/api")
app.include_router(daily_word.router, prefix="/api")
app.include_router(log.router, prefix="/api")


@app.get("/health")
async def health():
    return {"status": "ok"}
