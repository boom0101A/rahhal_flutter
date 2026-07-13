@echo off
title Rahhal AI Clean Tool
echo ===================================================
echo             Rahhal AI Clean Tool
echo ===================================================
echo.

echo [1/3] Running flutter clean to delete build files...
call flutter clean

echo.
echo [2/3] Checking for generated Markdown codebase backups...

if exist "rahhal_codebase_md" (
    echo - Deleting rahhal_codebase_md directory...
    rmdir /s /q "rahhal_codebase_md"
) else (
    echo - rahhal_codebase_md directory not found (already clean).
)

if exist "rahhal_full_codebase.md" (
    echo - Deleting rahhal_full_codebase.md file...
    del /f /q "rahhal_full_codebase.md"
) else (
    echo - rahhal_full_codebase.md file not found (already clean).
)

if exist "rahhal_app_complete_report.md" (
    echo - Deleting rahhal_app_complete_report.md file...
    del /f /q "rahhal_app_complete_report.md"
) else (
    echo - rahhal_app_complete_report.md file not found (already clean).
)

echo.
echo [3/3] Deleting temporary logs...
if exist "*.log" (
    del /f /q *.log
)

echo.
echo ===================================================
echo Project is clean! Ready for new build.
echo ===================================================
echo.
pause
