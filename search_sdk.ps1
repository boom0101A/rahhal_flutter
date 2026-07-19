$outFile = "d:\dev_projects\rahhal_flutter\search_result.txt"
"=== Search Started at $(Get-Date) ===" | Out-File -FilePath $outFile -Encoding utf8

$drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root

foreach ($drive in $drives) {
    "Checking drive $drive ..." | Out-File -FilePath $outFile -Append -Encoding utf8
    try {
        Get-ChildItem -Path $drive -Recurse -ErrorAction SilentlyContinue -Force | 
            Where-Object { $_.Name -like "*commandlinetools*" -or $_.Name -like "*14742923*" -or $_.Name -like "*cmdline-tools*" } | 
            Select-Object FullName, Length, LastWriteTime | 
            Out-String | Out-File -FilePath $outFile -Append -Encoding utf8
    } catch {
        "Error reading $drive : $_" | Out-File -FilePath $outFile -Append -Encoding utf8
    }
}

"=== Search Completed ===" | Out-File -FilePath $outFile -Append -Encoding utf8
