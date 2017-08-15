<#

Script Name:  copy_MoviesByYear.ps1
By:  Zack Thompson / Created:  8/5/2017
Version: 1.0 / Updated:  8/5/2017 / By:  ZT

Description:  This script will allow for batch copying of files based on the Year in the title.

#>

# ============================================================
# Define Variables
# ============================================================
$Source = "M:\Library\Kids"
$Destination = "H:\Movies"
$Position=1

# ============================================================
# Script Body
# ============================================================
$filesToMove = Get-ChildItem $Source | Where { $_.Name -match "2014" }
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
