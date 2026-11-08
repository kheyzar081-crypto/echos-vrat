@echo off
cd /d "%~dp0"
echo Butuh Node.js terpasang (nodejs.org). Build butuh internet sekali.
echo.
if exist game rmdir /s /q game
xcopy /E /I /Y "..\game" "game" >nul
if errorlevel 1 (echo Folder ..\game tidak ketemu & pause & exit /b 1)
call npm install
call npm run build
echo.
echo Selesai. Cek folder dist\EchosVrat.exe
pause
