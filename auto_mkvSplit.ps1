<#

Script Name:  auto_mkvSplit.ps1
By:  Zack Thompson / Created:  8/15/2017
Version: 1.0 / Updated:  8/15/2017 / By:  ZT

Description:  This script will allow for batch splitting of files with the mkvmerge.exe toolset.

Notes:
    * At this time, this script assumes the mkvmerge toolset directory is in your PATH environment variable.
    * I may either expand on this script later or merge the code into my 'auto_mkvMerge.ps1 script.

#>

# ============================================================
# Define Variables
# ============================================================

# Define the File Extensions we're looking for
$fileExtensions = @()
$fileExtensions += "*.mkv"
$fileExtensions += "*.mp4"

# Define location to save log files.
$Destination = "$($env:SystemDrive)\ScriptLogs\auto_mkvSplit\"

# Set LogFile locations and names
$LogFile = $Destination + "Log_auto_mkvSplit.txt"

# ============================================================
# Script Body
# ============================================================

# Check to see directory exists and create it if not.
If (!(Test-Path -Path $Destination)) {
    New-Item -ItemType directory -Path $Destination
}

# Write to log that script started to process.
Write-Output "Script ran on $(Get-Date -UFormat "%m-%d-%Y %r")" | Out-File $LogFile -append

Write-Host "This script will allow for batch splitting of files with the mkvmerge.exe toolset." -ForegroundColor Cyan

# Request location of files to scan.
Write-Host "Please provide location to scan for files:  " -ForegroundColor Yellow -NoNewline
    $Location = Read-Host
    #$Location = "M:\Testing\Shows\"  # This is for development.

# Get all mkvs info from provided location
$mkvs = Get-ChildItem -Path "$($Location)\*" -Include $fileExtensions -Recurse | Select Name, Directory, FullName, Length

Write-Host "Please provide the parts in timecodes to split:  " -ForegroundColor Yellow -NoNewline
$Split = Read-Host
#$Split = "parts:00:01:30-21:30"  ### Single Episode Example, remove intro and credits
#$Split = "parts:00:01:30-00:11:30,00:11:30-21:30"  ### Two Epidsode Example, split them into two files
#$Split = "parts:00:01:00-"  ##  Remove beginning and keep the rest

ForEach ($mkv in $mkvs) {
    # Define Input and Output file names.
    $InputFile = "$($mkv.FullName)"
    $OutputFile = "$($mkv.Directory)\new_$($mkv.Name)"
    mkvmerge.exe "--output" $OutputFile --split $Split $InputFile
}

Write-Host "Script complete!" -ForegroundColor Cyan
Write-Host "You can find logs in the following location:  $($Destination)" -ForegroundColor Green

Write-Output "Script completed on $(Get-Date -UFormat "%m-%d-%Y %r")" | Out-File $LogFile -append
Write-Output "##################################################" | Out-File $LogFile -append

# eos