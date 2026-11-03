# Tüm servisleri durdurur
Write-Host "Servisler durduruluyor..." -ForegroundColor Yellow

Stop-Job -Name "AI-Service", "Backend" -ErrorAction SilentlyContinue
Remove-Job -Name "AI-Service", "Backend" -ErrorAction SilentlyContinue

# Port 8000 ve 8080'i kullanan processleri öldür
@(8000, 8080) | ForEach-Object {
    $port = $_
    $pid = (netstat -ano | Select-String ":$port " | Select-String "LISTENING" | ForEach-Object {
        ($_ -split "\s+")[-1]
    } | Select-Object -First 1)
    if ($pid) {
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        Write-Host "Port $port kapatildi (PID: $pid)" -ForegroundColor Green
    }
}

Write-Host "Tamam." -ForegroundColor Green
