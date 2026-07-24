# free_build_space.ps1
# Reclaims disk space that Flutter/Gradle/Shorebird builds leave behind.
# Everything deleted here REGENERATES on the next build — safe to run anytime
# the app is NOT currently building. Run from any PowerShell:
#     powershell -ExecutionPolicy Bypass -File tools\free_build_space.ps1
#
# What it does NOT touch (needed, keep): the Android SDK, the Pub cache,
# ~/.shorebird, and Gradle's downloaded dependency modules.

$ErrorActionPreference = 'SilentlyContinue'
$project = 'D:\dev_projects\rahhal_flutter'
$gradleCaches = 'C:\Users\klook\.gradle\caches'
$empty = Join-Path $env:TEMP '_empty_purge'

function Free { [math]::Round(((Get-PSDrive C).Free + (Get-PSDrive D).Free) / 1GB, 1) }

# Long-path-safe recursive delete (Gradle transforms nest past Windows' 260-char
# limit, which defeats a plain Remove-Item).
function Purge($path) {
  if (-not (Test-Path $path)) { return }
  New-Item -ItemType Directory -Force -Path $empty | Out-Null
  robocopy $empty $path /MIR /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
  Remove-Item -LiteralPath $path -Recurse -Force
}

$before = Free
Write-Host "Free before: $before GB (C+D)"

# 1. Stop Gradle daemons so their file locks release.
try { & (Join-Path $project 'android\gradlew.bat') --stop 2>&1 | Out-Null } catch {}
Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# 2. Project build output (biggest, ~2-3 GB per build).
Purge (Join-Path $project 'build')
Purge (Join-Path $project 'android\build')

# 3. Gradle transform + build caches (regenerated on next build).
Get-ChildItem $gradleCaches -Directory -Force | ForEach-Object {
  Purge (Join-Path $_.FullName 'transforms')
}
Get-ChildItem $gradleCaches -Directory -Force -Filter 'build-cache-*' | ForEach-Object {
  Purge $_.FullName
}

# 4. Clean up the temp mirror dir.
Remove-Item -LiteralPath $empty -Recurse -Force

$after = Free
Write-Host "Free after:  $after GB (C+D)"
Write-Host ("Reclaimed:   {0} GB" -f [math]::Round($after - $before, 1))
