@echo off
echo        DinamikUTB - Development Start
echo.

echo [1/3] Preparando entorno del backend...
cd /d "%~dp0backend"
if not exist ".venv" (
    echo Creando entorno virtual...
    python -m venv .venv
)
call .venv\Scripts\activate
pip install -r requirements.txt --quiet

echo [2/3] Iniciando FastAPI...
start "DinamikUTB Backend" cmd /k "cd /d %~dp0backend && call .venv\Scripts\activate && python -m uvicorn app.main:app --reload"
timeout /t 3 /nobreak >nul

echo [3/3] Preparando e iniciando Flutter...
cd /d "%~dp0frontend"
flutter pub get
flutter run -d chrome
