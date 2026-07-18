# Script to check drives and inspect C: drive top folders
Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}}, @{N='FreeGB';E={[math]::Round($_.FreeSpace/1GB,2)}} | Out-String | Write-Host

Write-Host "`n=== Root Folders and Files on C:\ ==="
Get-ChildItem -Path C:\ -ErrorAction SilentlyContinue | ForEach-Object {
    $item = $_
    $size = 0
    if ($item.PSIsContainer) {
        $size = (Get-ChildItem $item.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    } else {
        $size = $item.Length
    }
    [PSCustomObject]@{
        Name = $item.Name
        SizeGB = [math]::Round($size / 1GB, 2)
    }
} | Sort-Object SizeGB -Descending | Out-String | Write-Host

Write-Host "`n=== User Profile Folders in C:\Users\klook ==="
Get-ChildItem -Path "C:\Users\klook" -ErrorAction SilentlyContinue | ForEach-Object {
    $item = $_
    $size = 0
    if ($item.PSIsContainer) {
        $size = (Get-ChildItem $item.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    } else {
        $size = $item.Length
    }
    [PSCustomObject]@{
        Name = $item.Name
        SizeGB = [math]::Round($size / 1GB, 2)
    }
} | Sort-Object SizeGB -Descending | Out-String | Write-Host
