from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from routers import search, daily_word, log, feedback

load_dotenv()

app = FastAPI(
    title="今の辞書 API",
    description="辞書的意味と今の使われ方をAIで並列表示する辞書API",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(search.router, prefix="/api")
app.include_router(daily_word.router, prefix="/api")
app.include_router(log.router, prefix="/api")
app.include_router(feedback.router, prefix="/api")


@app.get("/")
async def root():
    return {"status": "ok"}


@app.get("/health")
async def health():
    return {"status": "ok"}
