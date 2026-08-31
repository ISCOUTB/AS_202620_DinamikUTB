from fastapi.middleware.cors import CORSMiddleware
from app.core.database import Base, engine
from app.requisitos.router import router as requisitos_router
from fastapi import FastAPI

app = FastAPI(
    title="DinamikUTB API",
    version="0.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)
app.include_router(requisitos_router)

@app.get("/")
def root():
    return {"message": "DinamikUTB API funcionando"}
