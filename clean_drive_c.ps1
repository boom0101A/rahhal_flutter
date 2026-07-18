# Script to clean up temporary files and caches on Drive C safely
# Run in PowerShell as Administrator or regular user

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "       Cleaning Drive C Temp & Cache Files     " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$beforeFree = (Get-Volume -DriveLetter C).SizeRemaining

# 1. User Temp Files
Write-Host "[1/6] Cleaning User Temp files (C:\Users\klook\AppData\Local\Temp)..." -ForegroundColor Yellow
$tempPath = "$env:LOCALAPPDATA\Temp"
if (Test-Path $tempPath) {
    Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Gradle Caches
Write-Host "[2/6] Cleaning Gradle build caches (C:\Users\klook\.gradle\caches)..." -ForegroundColor Yellow
$gradleCache = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCache) {
    Remove-Item -Path $gradleCache -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. NPM / PNPM Caches
Write-Host "[3/6] Cleaning NPM & PNPM caches..." -ForegroundColor Yellow
$npmCache = "$env:LOCALAPPDATA\npm-cache"
if (Test-Path $npmCache) { Remove-Item -Path $npmCache -Recurse -Force -ErrorAction SilentlyContinue }
$pnpmCache = "$env:LOCALAPPDATA\pnpm-cache"
if (Test-Path $pnpmCache) { Remove-Item -Path $pnpmCache -Recurse -Force -ErrorAction SilentlyContinue }

# 4. Dart Analysis Server Cache
Write-Host "[4/6] Cleaning Dart Server analysis cache..." -ForegroundColor Yellow
$dartServer = "$env:LOCALAPPDATA\.dartServer"
if (Test-Path $dartServer) { Remove-Item -Path $dartServer -Recurse -Force -ErrorAction SilentlyContinue }

# 5. Empty Recycle Bin
Write-Host "[5/6] Emptying Recycle Bin..." -ForegroundColor Yellow
Clear-RecycleBin -DriveLetter C -Confirm:$false -ErrorAction SilentlyContinue

# 6. Flutter Clean in current project
Write-Host "[6/6] Cleaning Flutter build artifacts in current project..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path ".dart_tool") {
    Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
}

$afterFree = (Get-Volume -DriveLetter C).SizeRemaining
$freedBytes = $afterFree - $beforeFree
$freedGB = [math]::round($freedBytes / 1GB, 2)
$totalFreeGB = [math]::round($afterFree / 1GB, 2)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "               Cleanup Complete!               " -ForegroundColor Green
Write-Host ("Freed Space: {0} GB" -f $freedGB) -ForegroundColor Green
Write-Host ("Current Free Space on Drive C: {0} GB" -f $totalFreeGB) -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
pause
