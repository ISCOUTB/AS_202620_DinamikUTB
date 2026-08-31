@echo off

echo        DinamikUTB - Development Start
echo.

echo [1/2] Starting FastAPI...
start "DinamikUTB Backend" cmd /k "cd /d %~dp0backend && call .venv\Scripts\activate && python -m uvicorn app.main:app --reload"

timeout /t 3 /nobreak >nul

echo [2/2] Starting Flutter...
cd /d "%~dp0frontend"
flutter run -d chrome
