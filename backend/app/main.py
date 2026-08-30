from app.core.database import Base, engine
from app.requisitos.router import router as requisitos_router
from fastapi import FastAPI

app = FastAPI(
    title="DinamikUTB API",
    version="0.1.0"
)

Base.metadata.create_all(bind=engine)
app.include_router(requisitos_router)

@app.get("/")
def root():
    return {"message": "DinamikUTB API funcionando"}
