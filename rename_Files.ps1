<#

Script Name:  rename_Files.ps1
By:  Zack Thompson / Created:  8/13/2017
Version: 1.0 / Updated:  8/13/2017 / By:  ZT

Description:  This script will allow for batch renaming of files based on a matching string in the title.
    (I'm mainly using this in conjunction with my auto_mkvMerge script.)

#>

# ============================================================
# Define Variables
# ============================================================
Write-Host "Please provide source directory:  " -ForegroundColor Yellow -NoNewline
$Source = Read-Host
    # $Source = "M:\Library\Test"  ### For hard coding values if you don't want to enter it each time.

Write-Host "Please provide the year:  " -ForegroundColor Green -NoNewline
$String = Read-Host
    # $String = "orig_"  ### For hard coding values if you don't want to enter it each time.

$Position=1

# ============================================================
# Script Body
# ============================================================
$filesToRemane = Get-ChildItem $Source -Recurse | Where { $_.Name -match $String }
$totalFiles=$filesToRemane.count

Write-Host "There are $totalFiles matching the criteria."

ForEach ( $File in $filesToRemane ) {
    Write-Host "File $Position of $totalFiles."
    Write-Host "Old Name:  $File"
    Write-Progress -Activity "Renaming Files" -Status "Renaming File $File" -PercentComplete (($Position/$totalFiles)*100)
    $File | Rename-Item $File.FullName -NewName { $_.Name -replace $String, "" }
    $Position++
}
