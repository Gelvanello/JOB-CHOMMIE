@echo off
setlocal enabledelayedexpansion

REM AI Job Chommie Port Reconfiguration Script (Windows)
REM This script reconfigures the application to use the correct ports:
REM - Frontend: 5173 (instead of 3000)
REM - Backend: 5000 (no change)

echo =========================================
echo AI Job Chommie Port Reconfiguration Tool
echo =========================================
echo Frontend: 3000 -^> 5173
echo Backend: 5000 (no change)
echo =========================================
echo.

REM Configuration
set FRONTEND_OLD_PORT=3000
set FRONTEND_NEW_PORT=5173
set BACKEND_PORT=5000
set BACKUP_DIR=backup_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set BACKUP_DIR=%BACKUP_DIR: =0%
set LOG_FILE=reconfigure_ports_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
set LOG_FILE=%LOG_FILE: =0%

REM Base directories
set FRONTEND_DIR=home\ubuntu\AIJobChommie\AIJobChommiefinal_package\ai-job-chommie-src\ai-job-chommie-frontend
set BACKEND_DIR=home\ubuntu\AIJobChommie\AIJobChommiefinal_package\ai-job-chommie-src\ai-job-chommie-backend
set ROOT_DIR=home\ubuntu\AIJobChommie\AIJobChommiefinal_package\ai-job-chommie-src

REM Start logging
echo Port reconfiguration started at %date% %time% > "%LOG_FILE%"

REM Step 1: Create backup
echo Step 1: Creating backup...
mkdir "%BACKUP_DIR%" 2>nul

REM Backup files
echo Backing up configuration files...
if exist "%FRONTEND_DIR%\vite.config.js" copy "%FRONTEND_DIR%\vite.config.js" "%BACKUP_DIR%\" >nul
if exist "%FRONTEND_DIR%\package.json" copy "%FRONTEND_DIR%\package.json" "%BACKUP_DIR%\" >nul
if exist "%FRONTEND_DIR%\src\lib\api.js" copy "%FRONTEND_DIR%\src\lib\api.js" "%BACKUP_DIR%\api.js" >nul
if exist "%BACKEND_DIR%\src\main.py" copy "%BACKEND_DIR%\src\main.py" "%BACKUP_DIR%\" >nul
if exist "%BACKEND_DIR%\src\config.py" copy "%BACKEND_DIR%\src\config.py" "%BACKUP_DIR%\" >nul
if exist "%ROOT_DIR%\docker-compose.yml" copy "%ROOT_DIR%\docker-compose.yml" "%BACKUP_DIR%\" >nul
if exist "%ROOT_DIR%\start.bat" copy "%ROOT_DIR%\start.bat" "%BACKUP_DIR%\" >nul
echo [OK] Backup created in %BACKUP_DIR%
echo.

REM Step 2: Stop running processes
echo Step 2: Stopping processes on ports...

REM Kill processes on ports
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%FRONTEND_OLD_PORT%"') do (
    echo Stopping process on port %FRONTEND_OLD_PORT% (PID: %%a)
    taskkill /F /PID %%a >nul 2>&1
)

for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%FRONTEND_NEW_PORT%"') do (
    echo Stopping process on port %FRONTEND_NEW_PORT% (PID: %%a)
    taskkill /F /PID %%a >nul 2>&1
)

for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%BACKEND_PORT%"') do (
    echo Stopping process on port %BACKEND_PORT% (PID: %%a)
    taskkill /F /PID %%a >nul 2>&1
)

echo [OK] Processes stopped
echo.

REM Step 3: Update configuration files
echo Step 3: Updating configuration files...

REM Create PowerShell script for file updates
echo Creating update script...
(
echo # PowerShell script to update port configurations
echo $files = @(
echo     "%FRONTEND_DIR%\vite.config.js",
echo     "%FRONTEND_DIR%\package.json",
echo     "%FRONTEND_DIR%\src\lib\api.js",
echo     "%BACKEND_DIR%\src\main.py",
echo     "%BACKEND_DIR%\src\config.py",
echo     "%ROOT_DIR%\docker-compose.yml",
echo     "%ROOT_DIR%\start.bat",
echo     "%ROOT_DIR%\README.md",
echo     "%ROOT_DIR%\QUICK_START.md",
echo     "%ROOT_DIR%\GET_STARTED.md",
echo     "%ROOT_DIR%\API_DOCUMENTATION.md",
echo     "%ROOT_DIR%\DEPLOYMENT.md"
echo ^)
echo.
echo foreach ^($file in $files^) {
echo     if ^(Test-Path $file^) {
echo         Write-Host "Updating: $file"
echo         $content = Get-Content $file -Raw
echo         $content = $content -replace ':3000', ':5173'
echo         $content = $content -replace 'port\s+3000', 'port 5173'
echo         $content = $content -replace 'PORT\s+3000', 'PORT 5173'
echo         $content = $content -replace 'localhost:3000', 'localhost:5173'
echo         $content = $content -replace '127\.0\.0\.1:3000', '127.0.0.1:5173'
echo         Set-Content -Path $file -Value $content -NoNewline
echo     }
echo }
echo.
echo # Update vite.config.js to ensure port is set
echo $viteConfig = "%FRONTEND_DIR%\vite.config.js"
echo if ^(Test-Path $viteConfig^) {
echo     $content = Get-Content $viteConfig -Raw
echo     if ^($content -notmatch 'server:'^ ) {
echo         $content = $content -replace '^(export default defineConfig\({[^}]*)(}\))$', '$1  server: {`n    port: 5173,`n    host: true,`n    strictPort: true`n  },`n$2'
echo         Set-Content -Path $viteConfig -Value $content -NoNewline
echo     }
echo }
echo.
echo # Update package.json dev script
echo $packageJson = "%FRONTEND_DIR%\package.json"
echo if ^(Test-Path $packageJson^) {
echo     $content = Get-Content $packageJson -Raw
echo     $content = $content -replace '"dev":\s*"vite"', '"dev": "vite --port 5173"'
echo     Set-Content -Path $packageJson -Value $content -NoNewline
echo }
echo.
echo # Check for .env files
echo $envFiles = @(
echo     "%FRONTEND_DIR%\.env",
echo     "%FRONTEND_DIR%\.env.local",
echo     "%FRONTEND_DIR%\.env.development",
echo     "%FRONTEND_DIR%\.env.production",
echo     "%BACKEND_DIR%\.env",
echo     "%BACKEND_DIR%\src\.env",
echo     "%ROOT_DIR%\.env"
echo ^)
echo.
echo foreach ^($envFile in $envFiles^) {
echo     if ^(Test-Path $envFile^) {
echo         Write-Host "Updating environment file: $envFile"
echo         $content = Get-Content $envFile -Raw
echo         $content = $content -replace ':3000', ':5173'
echo         $content = $content -replace 'VITE_API_BASE_URL=http://localhost:3000', 'VITE_API_BASE_URL=http://localhost:5000'
echo         Set-Content -Path $envFile -Value $content -NoNewline
echo     }
echo }
) > update_ports.ps1

REM Execute PowerShell script
powershell -ExecutionPolicy Bypass -File update_ports.ps1
del update_ports.ps1

echo [OK] Configuration files updated
echo.

REM Step 4: Create restore script
echo Creating restore script...
(
echo @echo off
echo echo Restoring AI Job Chommie port configuration...
echo.
echo copy "%BACKUP_DIR%\vite.config.js" "%FRONTEND_DIR%\" /Y ^>nul 2^>^&1
echo copy "%BACKUP_DIR%\package.json" "%FRONTEND_DIR%\" /Y ^>nul 2^>^&1
echo copy "%BACKUP_DIR%\api.js" "%FRONTEND_DIR%\src\lib\" /Y ^>nul 2^>^&1
echo copy "%BACKUP_DIR%\main.py" "%BACKEND_DIR%\src\" /Y ^>nul 2^>^&1
echo copy "%BACKUP_DIR%\config.py" "%BACKEND_DIR%\src\" /Y ^>nul 2^>^&1
echo copy "%BACKUP_DIR%\docker-compose.yml" "%ROOT_DIR%\" /Y ^>nul 2^>^&1
echo copy "%BACKUP_DIR%\start.bat" "%ROOT_DIR%\" /Y ^>nul 2^>^&1
echo.
echo echo [OK] Files restored from backup
echo pause
) > "%BACKUP_DIR%\restore.bat"

echo [OK] Restore script created
echo.

REM Step 5: Start services
echo Step 5: Starting services on correct ports...

REM Check if start.bat exists
if exist "%ROOT_DIR%\start.bat" (
    echo Starting services using start.bat...
    cd /d "%ROOT_DIR%"
    start "AI Job Chommie Launcher" cmd /c start.bat
) else (
    REM Start services manually
    echo Starting backend service...
    cd /d "%BACKEND_DIR%\src"
    if exist "venv\Scripts\activate.bat" (
        start "AI Job Chommie Backend" cmd /k "venv\Scripts\activate && python main.py"
    ) else (
        start "AI Job Chommie Backend" cmd /k "python main.py"
    )
    
    timeout /t 3 /nobreak >nul
    
    echo Starting frontend service...
    cd /d "%FRONTEND_DIR%"
    start "AI Job Chommie Frontend" cmd /k "npm run dev"
)

echo [OK] Services started
echo.

REM Wait for services to start
echo Waiting for services to start...
timeout /t 5 /nobreak >nul

REM Step 6: Verify services
echo Step 6: Verifying services...
echo.

REM Check if services are running
netstat -an | findstr ":%FRONTEND_NEW_PORT%" >nul
if %errorlevel% equ 0 (
    echo [OK] Frontend is running on port %FRONTEND_NEW_PORT%
) else (
    echo [WARNING] Frontend may not be running on port %FRONTEND_NEW_PORT%
)

netstat -an | findstr ":%BACKEND_PORT%" >nul
if %errorlevel% equ 0 (
    echo [OK] Backend is running on port %BACKEND_PORT%
) else (
    echo [WARNING] Backend may not be running on port %BACKEND_PORT%
)

echo.
echo =========================================
echo Port reconfiguration completed!
echo =========================================
echo Frontend: http://localhost:%FRONTEND_NEW_PORT%
echo Backend: http://localhost:%BACKEND_PORT%
echo.
echo Backup created at: %BACKUP_DIR%
echo Log file: %LOG_FILE%
echo.
echo To restore previous configuration, run:
echo   %BACKUP_DIR%\restore.bat
echo.
echo Port reconfiguration completed at %date% %time% >> "%LOG_FILE%"

pause