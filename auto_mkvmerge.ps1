<#

Script Name:  auto_mkvmerge.ps1
By:  Zack Thompson / Created:  3/19/2017
Version: 0.7 / Updated:  3/26/2017 / By:  ZT

Description:  This script will allow for batch processing of files with the mkvmerge.exe toolset.

Notes:
    * This script assumes the mkvmerge toolset directory is in your PATH enviroment variable.
    * This script is 'working' as desired, but by no means is finished -- more to come.

To do:
 Done = Add logging capabilities
 Done = Output original track list to CSV log
 Done = If you don't want to delete the files upon completion, dump file list to file for use later
    + Add option to delete files in this dump file
 + Adjust script to take values as arguments, or convert to a function.

#>

Write-Host "This script will allow for batch processing of files with the mkvmerge.exe toolset." -ForegroundColor Green

# ============================================================
# These functions are all questions asked during the processing of the script.
Function Question1 {
	$Title = "Do you want to continue?";
	$Message = "Do you want to continue?  Enter ? for more information on the options."
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Continue on this path of automation...";
	$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Quick, exit and never look back!";
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
	$script:Answer1 = $Host.UI.PromptForChoice($Title,$Message,$Options,0)
}

Function Question2 {
	$Title = "Are you sure you want to make the changes above?";
	$Message = "Are you sure you want to make the changes above?  Enter ? for more information on the options."
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Greatness awaits you!";
	$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No","You will never know what could have been!";
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
	$script:Answer2 = $Host.UI.PromptForChoice($Title,$Message,$Options,0)
}

Function Question3 {
	$Title = "Do you want to delete the original files?";
	$Message = "Do you want to delete the original files?  Enter ? for more information on the options."
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Poof!  No recovery from here!";
	$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No","This is the last turning back point!";
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
	$script:Answer3 = $Host.UI.PromptForChoice($Title,$Message,$Options,0)
}
# ============================================================


# ============================================================
# Define Variables
# ============================================================

$LineFeed = [char]0x000A
$Delete = '!'

# Declare Arrays
$mkvInfoResults = @()
$mkvObject = @()

# Define text that needs be trimmed from the output of mkvinfo.exe.
$Trims = @{}
$Trims.'|  + ' = ''
$Trims.'Track number: ' = '!'
$Trims.' (track ID for mkvmerge & mkvextract: ' = ':'
$Trims.')' = ''
$Trims.'Track type: ' = ''
$Trims.'Language: ' = ''
$Trims."$($LineFeed)" = ','

# Define location to the new destination for PST Files
$Destination = "$($env:SystemDrive)\ScriptLogs\"

# Set LogFile locations and names
$LogFile = $Destination + "Log_auto_mkvmerge.txt"
$mkvOriginals = $Destination + "mkvOriginals.txt"
$mkvReport = $Destination + "mkvReport.csv"

Write-Host "You can find logs in the following location:  $($Destination)" -ForegroundColor Cyan

# Request location of files to scan.
Write-Host "Please provide location to scan for files:  " -ForegroundColor Yellow -NoNewline
$Location = Read-Host
#$Location = "M:\Library\TV\test"  # This is for development.

# ============================================================
# Script Body
# ============================================================

# Check to see directory exists and create it if not.
if(!(Test-Path -Path $Destination)){
    New-Item -ItemType directory -Path $Destination
}

# Write to log that script started to process.
Write-Output "Script ran on $(Get-Date -UFormat "%m-%d-%Y %r")" | Out-File $LogFile -append

# Get all mkvs info from provided location
$mkvs = Get-ChildItem -Filter *.mkv -Path $Location -Recurse | Select Name, Directory, FullName

ForEach ($mkv in $mkvs) {

    # Get data from mkvs with mkvinfo.exe.
    $mkvInfo = cmd /c mkvinfo.exe $mkv.FullName | Where-Object -FilterScript { ($_ -like '*Track number*') -or ($_ -like '*Track type*') -or ($_ -like '*Language*') -and ($_ -notlike '*Chapter*') } | Out-String

    # Trim the data to a more usable format.
    ForEach ($Key in $Trims.Keys) {
        $mkvInfo = ($mkvInfo.Replace($Key, $Trims.$Key))
        $mkvInfo = $mkvInfo -replace '[0-9]:', ''
    }

    # Further formatting on the data.
    $mkvInfoResults = $mkvInfo -split '!'
    $mkvInfoResults = $mkvInfoResults | Where-Object { $_ }

    # Put data into a hash table that will be imported into a custom object.
    ForEach ($mkvResult in $mkvInfoResults) {
 
        # Split line by commas.
        $mkvData = $mkvResult.Split(',')

        # Adding data into a hash table, triming the data again.
        $mkvProperties = @{
            Name = $mkv.Name
            Track = $mkvData[0].TrimEnd()
            Type = $mkvData[1].TrimEnd()
            Language = $mkvData[2].TrimEnd()
            Directory = $mkv.Directory
        }

        # Add hash table to custom object
        $mkvObject += New-Object PSObject -Property $mkvProperties

    }
}

# Display results to screen for review
Write-Host "All tracks for provided files, please review before continuing..." -ForegroundColor Cyan
$mkvObject | Select-Object Track, Type, Language, Name |  FT

# Dump results to Log Files
Write-Output "All tracks found in scan:" | Out-File $LogFile -Append
Write-Output ($mkvObject | Select-Object Track, Type, Language, Name |  FT) | Out-File $LogFile -Append

# Dump original results with full track list to a CSV file for review.
($mkvObject | Select-Object Track, Type, Language, Name, Directory) | Export-Csv $mkvReport -Append

# Function Question1
Question1

If ($Answer1 -eq 0) {

    # Define array
    $mkvRemove = @()

    # Here I grab the languages I want to remove.
    ForEach ($mkvEdit in $mkvObject) {
        If (($mkvEdit.Language -ne "eng") -and ($mkvEdit.Language -ne "")) {
            $mkvRemove += $mkvEdit
        }
    }

    # Group the results by file (so we can perform one mkvmerge per file).
    $mkvItems = $mkvRemove | Group-Object -Property Name

    If ($mkvItems.Count -lt '1') {
        Write-Host "Nothing to edit in provided directory!" -ForegroundColor Magenta
        Write-Output "Nothing to edit in provided directory!" | Out-File $LogFile -Append
        Exit
    }
    Else {
        Write-Host "The following number of tracks were found per file.  These tracks will be removed:" -ForegroundColor Cyan
        $mkvItems | Select-Object Count, Name | FT -AutoSize
        Write-Host "(Last point to turn back!)" -ForegroundColor Red

        # Dump results to Log File
        Write-Output "The following number of tracks were found per file.  These tracks will be removed:" | Out-File $LogFile -Append
        Write-Output ($mkvItems | Select-Object Count, Name | FT -AutoSize) | Out-File $LogFile -Append

    }
}

# Function Question2
Question2

If ($Answer2 -eq 0) {

    # Performing the changes...
    Write-Host "No turning back now..." -ForegroundColor Cyan
    Write-Host "No worries, no changes to the original files will be made yet!  XD" -ForegroundColor Cyan

    # Define Array
    $DeleteOrig = @()

    ForEach ($mkvItem in $mkvItems) {

        # Get all the audio tracks to be removed, and deliminate the with commas.
        $mkvVideos = ($mkvItem.Group | Where-Object { $_.Type -eq "video" } | Select-Object -ExpandProperty Track) -join ','
        
        # Get all the audio tracks to be removed, and deliminate the with commas.
        $mkvAudios = ($mkvItem.Group | Where-Object { $_.Type -eq "audio" } | Select-Object -ExpandProperty Track) -join ','

        # Get all the subtitle tracks to be removed, and deliminate the with commas.
        $mkvSubtitles = ($mkvItem.Group | Where-Object { $_.Type -eq "subtitles" } | Select-Object -ExpandProperty Track) -join ','

        # Define Input and Output file names.
        $InputFile = "$($mkvItem.Group | Select-Object Directory -Unique -ExpandProperty Directory)\$($mkvItem.Name)"
        $OutputFile = "$($mkvItem.Group | Select-Object Directory -Unique -ExpandProperty Directory)\new_$($mkvItem.Name)"

        # Perform mkvmerge on file.
#        Write-Host "mkvmerge.exe --output $OutputFile --audio-tracks $($Delete)$($mkvAudios) --subtitle-tracks $($Delete)$($mkvSubtitles) $InputFile"   # This is for development.
        mkvmerge.exe --output $OutputFile --audio-tracks "$($Delete)$($mkvAudios)" --subtitle-tracks "$($Delete)$($mkvSubtitles)" $InputFile

        # Perform mkvpropedit on file (delete title and set video track to eng).
#        Write-Host "mkvpropedit.exe $OutputFile --delete title --edit track:1 --set language=eng"   # This is for development.
        mkvpropedit.exe $OutputFile --delete title --edit track:1 --set language=eng
 
        # Label original as such.
        Rename-Item $InputFile -NewName "orig_$($InputFile)"
        $DeleteOrig += "$($mkvItem.Group | Select-Object Directory -Unique -ExpandProperty Directory)\orig_$($mkvItem.Name)"

        # Rename 'new' as 'production.'
        Rename-Item $OutputFile -NewName $InputFile
    }
}

Write-Host "Here are the original files, do you want to nuke these?" -ForegroundColor Red
$DeleteOrig

# Dump files to be deleted to a log file for possible use later.
Write-Output ($DeleteOrig) | Out-File $mkvOriginals -Append

# Function Question3
Question3

If ($Answer3 -eq 0) {

#    $DeleteOrig | Remove-Item

}

Write-Output "Script completed on $(Get-Date -UFormat "%m-%d-%Y %r")" | Out-File $LogFile -append
Write-Output "##################################################" | Out-File $LogFile -append

# eos