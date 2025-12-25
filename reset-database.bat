@echo off
chcp 65001 >nul
echo ============================================
echo    SecureBank - Database Reset Utility
echo ============================================
echo.
echo [WARNING] This operation will permanently delete ALL data.
echo.
set /p CONFIRM="Type 'yes' to continue: "
if not "%CONFIRM%"=="yes" (
    echo [INFO] Operation cancelled by user
    pause
    exit /b 0
)

echo Enter MySQL root password (default: password):
set /p MYSQL_PASSWORD="Password: "
if "%MYSQL_PASSWORD%"=="" set MYSQL_PASSWORD=password

echo Resetting database...
mysql -u root -p%MYSQL_PASSWORD% -e "DROP DATABASE IF EXISTS banking_system; CREATE DATABASE banking_system; GRANT ALL PRIVILEGES ON banking_system.* TO 'root'@'localhost'; FLUSH PRIVILEGES;" 2>nul

if %errorlevel% equ 0 (
    echo [OK] Database reset completed successfully
    echo.
    echo Restart the application to regenerate demo data
) else (
    echo [ERROR] Database reset failed
    echo Verify MySQL credentials and connection
)

pause
