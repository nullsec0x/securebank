@echo off
chcp 65001 >nul
echo ============================================
echo    SecureBank - Setup Script for Windows
echo ============================================
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run this script as Administrator
    echo         (Right-click -> Run as Administrator)
    echo.
    pause
    exit /b 1
)

echo [INFO] Checking prerequisites...
echo.

REM Check Java
where java >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=3" %%i in ('java -version 2^>^&1 ^| findstr /i "version"') do (
        set "JAVA_VERSION=%%i"
    )
    echo [OK] Java detected: %JAVA_VERSION%
) else (
    echo [ERROR] Java not found
    echo.
    echo Download Java 17:
    echo - https://adoptium.net/temurin/releases
    echo - https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html
    echo.
    pause
    exit /b 1
)

REM Check Maven
where mvn >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=3" %%i in ('mvn -v ^| findstr "Apache Maven"') do (
        set "MAVEN_VERSION=%%i"
    )
    echo [OK] Maven detected: %MAVEN_VERSION%
) else (
    echo [ERROR] Maven not found
    echo.
    echo Download Maven:
    echo - https://maven.apache.org/download.cgi
    echo Installation guide:
    echo - https://maven.apache.org/install.html
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo           Database Setup
echo ============================================
echo.
echo Database setup options:
echo.
echo [1] Install MySQL (if not installed)
echo [2] Skip database setup (manual configuration)
echo [3] MySQL already installed and running
echo.
set /p CHOICE="Select option (1-3): "

if "%CHOICE%"=="1" (
    echo Downloading MySQL Installer...
    
    powershell -Command "Invoke-WebRequest -Uri 'https://dev.mysql.com/get/mysql-installer-community-8.0.37.0.msi' -OutFile 'mysql-installer.msi'"
    
    if exist "mysql-installer.msi" (
        echo Starting MySQL installer...
        echo Required settings:
        echo 1. Setup Type: Developer Default
        echo 2. Root password: password
        echo 3. Ensure MySQL service is running
        msiexec /i "mysql-installer.msi"
        del "mysql-installer.msi"
    ) else (
        echo [ERROR] Failed to download MySQL installer
        echo Manual download:
        echo https://dev.mysql.com/downloads/installer/
    )
) else if "%CHOICE%"=="3" (
    goto :database_check
)

:database_check
echo.
echo Checking MySQL availability...
mysql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] MySQL not found in PATH
    echo.
    echo Manual database setup required:
    echo 1. Open MySQL Command Line Client
    echo 2. Execute:
    echo    CREATE DATABASE banking_system;
    echo    GRANT ALL PRIVILEGES ON banking_system.* TO 'root'@'localhost';
    echo    FLUSH PRIVILEGES;
    echo 3. Press Enter when finished
    pause
) else (
    echo [OK] MySQL detected. Initializing database...
    
    echo Enter MySQL root password (default: password):
    set /p MYSQL_PASSWORD="Password: "
    
    if "%MYSQL_PASSWORD%"=="" set MYSQL_PASSWORD=password
    
    echo Creating database...
    mysql -u root -p%MYSQL_PASSWORD% -e "CREATE DATABASE IF NOT EXISTS banking_system;" 2>nul
    if %errorlevel% equ 0 (
        mysql -u root -p%MYSQL_PASSWORD% -e "GRANT ALL PRIVILEGES ON banking_system.* TO 'root'@'localhost';" 2>nul
        mysql -u root -p%MYSQL_PASSWORD% -e "FLUSH PRIVILEGES;" 2>nul
        echo [OK] Database setup completed successfully
    ) else (
        echo [ERROR] Failed to connect to MySQL
        echo Verify credentials and try again
        pause
        exit /b 1
    )
)

echo.
echo ============================================
echo           Building Project
echo ============================================
echo.
echo Building SecureBank using Maven...
call mvn clean install -q

if %errorlevel% equ 0 (
    echo [OK] Build completed successfully
) else (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

echo.
echo ============================================
echo           Ready to Run
echo ============================================
echo.
echo Setup completed successfully
echo.
echo Quick start:
echo 1. Run application: mvn spring-boot:run
echo 2. Open browser: http://localhost:8080
echo 3. Default accounts:
echo    - Admin: admin / admin123
echo    - User:  john  / password123
echo.
echo Database details:
echo    - Name: banking_system
echo    - Username: root
echo    - Password: password (or custom)
echo.
echo Project structure:
echo    - Main class: src/main/java/com/banking/system/BankApplication.java
echo    - Configuration: src/main/resources/application.properties
echo.
pause
