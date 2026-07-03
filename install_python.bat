@echo off
echo ========================================
echo PR Review Agent - Quick Python Install
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Python is already installed!
    python --version
    echo.
    echo Ready to test! Run:
    echo   python pr_review_agent.py https://github.com/microsoft/vscode/pull/200000
    echo.
    pause
    exit /b
)

echo Python is not installed yet.
echo.
echo Opening Microsoft Store to install Python...
echo.
echo After installing:
echo   1. Close and reopen this window
echo   2. Run setup_and_test.ps1 or use:
echo      python pr_review_agent.py [PR_URL]
echo.

REM Open Microsoft Store to Python page
start ms-windows-store://pdp/?ProductId=9NRWMJP3717K

pause
