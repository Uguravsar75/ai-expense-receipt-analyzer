# ============================================
# YapayZeka FaturaAnaliz - Start All Services
# ============================================

$rootDir = $PSScriptRoot
$backendDir = Join-Path $rootDir "backend-api"
$aiServiceDir = Join-Path $rootDir "ai-service"
$mobileDir = Join-Path $rootDir "mobile_app"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All Services - Startup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1. BACKEND (JAVA - PORT 8080)
# ============================================
Write-Host "[1/3] Backend API (Spring Boot)..." -ForegroundColor Yellow
Write-Host "      Port: 8080" -ForegroundColor Gray
Write-Host "      Database: H2" -ForegroundColor Gray

$jarFile = Join-Path $backendDir "target\backend-0.0.1-SNAPSHOT.jar"
if (-not (Test-Path $jarFile)) {
    Write-Host "      Building Backend JAR with Maven Wrapper..." -ForegroundColor Yellow
    Push-Location $backendDir
    .\mvnw.cmd clean package -DskipTests
    Pop-Location
}

if (Test-Path $jarFile) {
    Write-Host "      JAR found" -ForegroundColor Green
    Write-Host ""

    Start-Process powershell -ArgumentList @"
        cd '$backendDir'
        Write-Host 'Starting Backend...' -ForegroundColor Cyan
        java -jar target\backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=h2
        Write-Host 'Backend stopped.' -ForegroundColor Red
        Read-Host 'Press Enter'
"@

    Write-Host "      Backend terminal opened. Waiting 10 seconds..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
} else {
    Write-Host "      ERROR: JAR not found" -ForegroundColor Red
    Write-Host "      Run: cd $backendDir && .\mvnw clean package -DskipTests" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# ============================================
# 2. AI SERVICE (PYTHON - PORT 8000)
# ============================================
Write-Host "[2/3] AI Service (FastAPI)..." -ForegroundColor Yellow
Write-Host "      Port: 8000" -ForegroundColor Gray
Write-Host "      URL: http://localhost:8000" -ForegroundColor Gray

$venvPython = Join-Path $aiServiceDir "venv\Scripts\python.exe"
if (Test-Path $venvPython -PathType Leaf) {
    Write-Host "      venv found" -ForegroundColor Green
    Write-Host ""

    Start-Process powershell -ArgumentList @"
        cd '$aiServiceDir'
        Write-Host 'Starting AI Service...' -ForegroundColor Cyan
        .\venv\Scripts\python.exe main.py
        Write-Host 'AI Service stopped.' -ForegroundColor Red
        Read-Host 'Press Enter'
"@

    Write-Host "      AI Service terminal opened. Waiting 5 seconds..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
} else {
    Write-Host "      Starting AI Service with system Python..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList @"
        cd '$aiServiceDir'
        Write-Host 'Starting AI Service...' -ForegroundColor Cyan
        python main.py
        Write-Host 'AI Service stopped.' -ForegroundColor Red
        Read-Host 'Press Enter'
"@
    Start-Sleep -Seconds 5
}

Write-Host ""

# ============================================
# 3. MOBILE APP (FLUTTER)
# ============================================
Write-Host "[3/3] Mobile App (Flutter)..." -ForegroundColor Yellow
Write-Host "      Platform: Android Emulator" -ForegroundColor Gray
Write-Host "      Backend: http://10.0.2.2:8080/api" -ForegroundColor Gray

if (Test-Path (Join-Path $mobileDir "pubspec.yaml") -PathType Leaf) {
    Write-Host "      Flutter project found" -ForegroundColor Green
    Write-Host ""

    Start-Process powershell -ArgumentList @"
        cd '$mobileDir'
        Write-Host 'Starting Flutter app...' -ForegroundColor Cyan
        flutter run
"@

    Write-Host "      Flutter terminal opened." -ForegroundColor Cyan
} else {
    Write-Host "      ERROR: Flutter project not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All Services Started!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services:" -ForegroundColor Cyan
Write-Host "  - Backend:  http://localhost:8080/api" -ForegroundColor White
Write-Host "  - AI:       http://localhost:8000" -ForegroundColor White
Write-Host "  - Flutter:  Emulator (10.0.2.2:8080/api)" -ForegroundColor White
Write-Host ""
Write-Host "Health Checks:" -ForegroundColor Cyan
Write-Host "  - Backend:  http://localhost:8080/api/health" -ForegroundColor White
Write-Host "  - AI:       http://localhost:8000/health" -ForegroundColor White
Write-Host ""
