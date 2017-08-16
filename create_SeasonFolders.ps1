<#

Script Name:  create_SeasonFolders.ps1
By:  Zack Thompson / Created:  8/13/2017
Version: 1.0 / Updated:  8/13/2017 / By:  ZT

Description:  This script will create a "Season [1..2..3..]" up to the number specified.

#>

# ============================================================
# Define Variables
# ============================================================
Write-Host "Enter the location to create Season folders:  " -NoNewline
    $Location = Read-Host

Write-Host "Enter the number of Seasons to create:  " -NoNewline
    $numberSeasons = Read-Host

# ============================================================
# Script Body
# ============================================================
While ($numberSeasons -ne 0) {
    $Season = "Season $($numberSeasons)"
    new-item -path $Location -name $Season -itemtype directory
    $numberSeasons = ($numberSeasons - 1)
}
