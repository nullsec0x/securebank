@echo off
chcp 65001 >nul
echo  Starting SecureBank...
echo.
echo ⚠️  Make sure MySQL is running!
echo.
echo Starting Spring Boot application...
echo Press Ctrl+C to stop
echo.
call mvn spring-boot:run
pause
