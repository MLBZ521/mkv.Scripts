<#

Script Name:  copy_MoviesByYear.ps1
By:  Zack Thompson / Created:  8/5/2017
Version: 1.1 / Updated:  8/14/2017 / By:  ZT

Description:  This script will allow for batch copying of files based on the Year in the title.

#>

# ============================================================
# Define Variables
# ============================================================
Write-Host "Please provide source directory:  " -ForegroundColor Yellow -NoNewline
$Source = Read-Host
    # $Source = "M:\Library\Kids"  ### For hard coding values if you don't want to enter it each time.

Write-Host "Please provide destintation directory:  " -ForegroundColor Green -NoNewline
$Destination = Read-Host
    # $Destination = "H:\Movies"  ### For hard coding values if you don't want to enter it each time.

Write-Host "Please provide the year:  " -ForegroundColor Cyan -NoNewline
$Year = Read-Host

$Position=0

# ============================================================
# Script Body
# ============================================================
$filesToMove = Get-ChildItem $Source | Where { $_.Name -match $Year }
$totalFiles=$filesToMove.count

Write-Host "There are $totalFiles matching the criteria."

ForEach ( $File in $filesToMove ) {
    If (!(Test-Path -Path "$Destination\$File")){
        Write-Host "$File does not exist on the destintation drive.  Copying now..."
        Write-Host "File $Position of $totalFiles."
        Write-Progress -Activity "Copying data from $Source to $Destination" -Status "Copying File $File" -PercentComplete (($Position/$totalFiles)*100)
        Copy-Item $File.FullName $Destination -Recurse
        $Position++
    }
}
