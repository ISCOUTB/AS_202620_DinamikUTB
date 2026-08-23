from fastapi import FastAPI

app = FastAPI(
    title="DinamikUTB API",
    version="0.1.0"
)

@app.get("/")
def root():
    return {"message": "DinamikUTB API funcionando"}
