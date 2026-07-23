@echo off
echo ==========================================
echo       Running Database Migrations
echo ==========================================
call npm run migrate:latest
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Migration failed with code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ==========================================
echo          Running Database Seeds
echo ==========================================
call npm run seed:run
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Seeding failed with code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ==========================================
echo   Migration and Seeding Completed Successfully!
echo ==========================================
pause
