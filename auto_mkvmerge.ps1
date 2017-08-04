<#

Script Name:  auto_mkvmerge.ps1
By:  Zack Thompson / Created:  3/19/2017
Version: 0.10 / Updated:  4/11/2017 / By:  ZT

Description:  This script will allow for batch processing of files with the mkvmerge.exe toolset.

Notes:
    * At this time, this script assumes the mkvmerge toolset directory is in your PATH environment variable.
    * This script is 'working' as desired, but by no means is finished -- more to come.

To do:
 Done = Sort files after Get-ChildItem to put in Alpha Numeric Order (just for aesthetics and ease of review).
 Done = Add a count to know how many files were found and current progress of the run.
 Done = Account for files that only the video file is listed as an 'unwanted' language -- so mkvmerge is not run against this file.
 Done = Account for files that only have 'unwanted' audio languages -- so we don't remove the only audio language.
 + Will try to add a way to select tracks based on their 'name', for groups files, to remove those tracks across files.
 + Adjust script to take values as arguments, or convert script to a function.

#>

# ============================================================
# These functions are all questions asked during the processing of the script.

Function Question0 {
	$Title = "Choose action to perform";
	$Message = "Do you want run mkvmerge or delete a batch of originals?  Enter ? for more information on the options."
	$Run = New-Object System.Management.Automation.Host.ChoiceDescription "&Run mkvmerge","Run mkvmerge on a folder.";
	$Batch = New-Object System.Management.Automation.Host.ChoiceDescription "&Batch delete","Delete a batch of original files from a prior log.";
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Run,$Batch);
	$script:Answer0 = $Host.UI.PromptForChoice($Title,$Message,$Options,0)
}

Function Question1 {
	$Title = "Continue?";
	$Message = "Do you want to continue?  Enter ? for more information on the options."
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Continue on this path of automation...";
	$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Quick, exit and never look back!";
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
	$script:Answer1 = $Host.UI.PromptForChoice($Title,$Message,$Options,0)
}

Function Question2 {
	$Title = "Commit the changes above?";
	$Message = "Are you sure you want to make the changes above?  Enter ? for more information on the options."
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Greatness awaits you!";
	$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No","You will never know what could have been!";
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
	$script:Answer2 = $Host.UI.PromptForChoice($Title,$Message,$Options,0)
}

Function Question3 {
	$Title = "Delete original files?";
	$Message = "Do you want to delete the original files after mkvmerge completes?  Enter ? for more information on the options."
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

# Define location to save log files.
$Destination = "$($env:SystemDrive)\ScriptLogs\auto_mkvmerge\"

# Set LogFile locations and names
$LogFile = $Destination + "Log_auto_mkvmerge.txt"
$mkvOriginals = $Destination + "Log_mkvOriginals.txt"
$mkvReport = $Destination + "Log_mkvReport.csv"

# ============================================================
# Script Body
# ============================================================

# Check to see directory exists and create it if not.
if(!(Test-Path -Path $Destination)){
    New-Item -ItemType directory -Path $Destination
}

# Write to log that script started to process.
Write-Output "Script ran on $(Get-Date -UFormat "%m-%d-%Y %r")" | Out-File $LogFile -append

Write-Host "This script will allow for batch processing of files with the mkvmerge.exe toolset." -ForegroundColor Cyan

# Function Question0
Question0

If ($Answer0 -eq 1) {
    Write-Output "The option to batch delete original files was selected." | Out-File $LogFile -append
    Write-Host "Please provide list of files to delete:  " -ForegroundColor Yellow -NoNewline
    $OriginalsFile = Read-Host
    $Originals = Get-Content $OriginalsFile

    Write-Host "Deleteing original files..." -ForegroundColor DarkRed
    ForEach ($Original in $Originals) {
        Remove-Item -Path $Original
    }

    Write-Output "Script completed on $(Get-Date -UFormat "%m-%d-%Y %r")" | Out-File $LogFile -append
    Write-Output "##################################################" | Out-File $LogFile -append
    Exit
}


# Request location of files to scan.
Write-Host "Please provide location to scan for files:  " -ForegroundColor Yellow -NoNewline
$Location = Read-Host
#$Location = "M:\Library\TV\test"  # This is for development.

# Get all mkvs info from provided location
$mkvs = Get-ChildItem -Filter *.mkv -Path $Location -Recurse | Select Name, Directory, FullName, Length

# Sort the list by name.
$mkvs = $mkvs | Sort-Object Name

Write-Host "Number of files found in the scan: "  $mkvs.Count -ForegroundColor Green
Write-Output "Number of files found in the scan:  $($mkvs.Count)" | Out-File $LogFile -append


ForEach ($mkv in $mkvs) {

    # Get data from mkvs with mkvinfo.exe.
    $mkvInfo = cmd /c mkvinfo.exe $mkv.FullName | Where-Object -FilterScript { ($_ -like '*Track number*') -or ($_ -like '*Track type*') -or ($_ -like '*Language*') -and ($_ -notlike '*Chapter*') } | Out-String
#    $mkvInfo = cmd /c mkvinfo.exe $mkv.FullName | Where-Object -FilterScript { ($_ -like '*Track number*') -or ($_ -like '*Track type*') -or ($_ -like '*Language*')  -or ($_ -like '*Name*') -and ($_ -notlike '*Chapter*') } | Out-String  # Possible new feature

    # Trim the data to a more usable format.
    ForEach ($Key in $Trims.Keys) {
        $mkvInfo = ($mkvInfo.Replace($Key, $Trims.$Key))
        $mkvInfo = $mkvInfo -replace '[0-9]:', ''
    }

    # Further formatting on the data.
    $mkvInfoResults = $mkvInfo -split '!'
    $mkvInfoResults = $mkvInfoResults | Where-Object { $_ }

    # Get size of the file
    $mkvSize = "$([Math]::Round($mkv.Length / 1GB, 2))GB"

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
            Size = $mkvSize
            Length = $mkv.Length
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
($mkvObject | Select-Object Track, Type, Language, Name, Size, Directory) | Export-Csv $mkvReport -Append


# Function Question1
Question1


If ($Answer1 -eq 0) {

    # Define array
    $mkvObject2 = @()
    $mkvRemove = @()
    $mkvSizeOrig = @()

    # Check to see if there is only one audio track, I don't want to remove it if it's the only one.
    $mkvAudioCheck = $mkvObject | Group-Object -Property Name

    ForEach ($mkvCheck in $mkvAudioCheck) {
        $mkvAudioTracks = $($mkvCheck.Group | Where-Object { $_.Type -eq "audio" } | Select-Object -ExpandProperty Name).count
 
        If ($mkvAudioTracks -le 1) {
            $mkvObject2 += ($mkvCheck.Group | Where-Object { $_.Type -ne "audio" })
        }
        Else {
            $mkvObject2 += $mkvCheck.Group
        }
    }

    # Here I grab the languages I want to remove.
    ForEach ($mkvEdit in $mkvObject2) {

        # I don't want to include track 0, aka the Video track.
        If ($mkvEdit.Track -ne 0) {
            
            # In the future, I want to adjust this to where I can input the languages I want to find.
            If (($mkvEdit.Language -ne "eng") -and ($mkvEdit.Language -ne "")) {
                $mkvRemove += $mkvEdit
            }
        }
    }

    # Group the results by file (so we can perform one mkvmerge per file).
    $mkvItems = $mkvRemove | Group-Object -Property Name

    Write-Host "Number of files with unwanted tracks: "  $mkvItems.Count -ForegroundColor Green
    Write-Output "Number of files with unwanted tracks:  $($mkvItems.Count)" | Out-File $LogFile -append
    
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

        $mkvSizeOrig += ($mkvItems.Group | Select-Object Length -Unique)

    }
        
    $mkvSizeOrigTotalGB = "$([Math]::Round(($mkvSizeOrig | Measure-Object -Sum Length).Sum / 1GB, 2))GB"
}


# Function Question2
Question2

# Function Question3 -- Moved the order of this question so that the script completes without waiting after the possible long mkvmerge run.
Question3


If ($Answer2 -eq 0) {

    # Performing the changes...
    Write-Host "No turning back now..." -ForegroundColor Cyan
    Write-Host "No worries, no changes to the original files will be made yet!  XD" -ForegroundColor Cyan

    # Define Array
    $DeleteOrig = @()
    $mkvSizeNew = @()
    $mkvCount = 1

    ForEach ($mkvItem in $mkvItems) {
        
        Write-Host "Currently processing file $($mkvCount) of $($mkvItems.Count)" -ForegroundColor Green

        $mkvAudiosRemove = $null
        $DeleteAudios = $null
        $mkvSubtitlesRemove = $null
        $DeleteSubtitles = $null

        # Get all the audio tracks to be removed, and deliminate them with commas.
        $mkvAudios = ($mkvItem.Group | Where-Object { $_.Type -eq "audio" } | Select-Object -ExpandProperty Track) -join ','
        If ($mkvAudios -gt 0)  {
            $mkvAudiosRemove = "--audio-tracks"
            $DeleteAudios = '!'
        }
        
        # Get all the subtitle tracks to be removed, and deliminate them with commas.
        $mkvSubtitles = $($mkvItem.Group | Where-Object { $_.Type -eq "subtitles" } | Select-Object -ExpandProperty Track) -join ','
        If ($mkvSubtitles -gt 0)  {
            $mkvSubtitlesRemove = "--subtitle-tracks"
            $DeleteSubtitles = '!'
        }

        # Define Input and Output file names.
        $InputFile = "$($mkvItem.Group | Select-Object Directory -Unique -ExpandProperty Directory)\$($mkvItem.Name)"
        $OutputFile = "$($mkvItem.Group | Select-Object Directory -Unique -ExpandProperty Directory)\new_$($mkvItem.Name)"

        # Perform mkvmerge on file.
#        Write-Host "mkvmerge.exe "--output" $OutputFile $mkvAudiosRemove "$($DeleteAudios)$($mkvAudios)" $mkvSubtitlesRemove "$($DeleteSubtitles)$($mkvSubtitles)" $InputFile"   # This is for development.
        mkvmerge.exe "--output" $OutputFile $mkvAudiosRemove "$($DeleteAudios)$($mkvAudios)" $mkvSubtitlesRemove "$($DeleteSubtitles)$($mkvSubtitles)" $InputFile

        # Perform mkvpropedit on file (delete title and set video track to eng).
#        Write-Host "mkvpropedit.exe $OutputFile --delete title --edit track:1 --set language=eng"   # This is for development.
        mkvpropedit.exe $OutputFile --delete title --edit track:1 --set language=eng --set name=""
 
        # Label original as such.
        Rename-Item $InputFile -NewName "$($mkvItem.Group | Select-Object Directory -Unique -ExpandProperty Directory)\orig_$($mkvItem.Name)"
        $DeleteOrig += "$($mkvItem.Group | Select-Object Directory -Unique -ExpandProperty Directory)\orig_$($mkvItem.Name)"

        # Rename 'new' as 'production.'
        Rename-Item $OutputFile -NewName $InputFile

        $mkvSizeNew += Get-ChildItem -Path $InputFile | Select Length

        $mkvCount ++
    }

    $mkvSizeNewTotalGB = "$([Math]::Round(($mkvSizeNew | Measure-Object -Sum Length).Sum / 1GB, 2))GB"
    $TotalSaved = "$([Math]::Round(($mkvSizeOrigTotalGB - $mkvSizeNewTotalGB) / 1GB, 2))GB"

    Write-Host "Total original size of files modified:  $mkvSizeOrigTotalGB" -ForegroundColor Magenta
    Write-Host "Total new size of files modified:  $mkvSizeNewTotalGB" -ForegroundColor Yellow
    Write-Host "Size saved:  $TotalSaved" -ForegroundColor Green
    
    Write-Output "Total original size of files modified:  $mkvSizeOrigTotalGB" | Out-File $LogFile -append
    Write-Output "Total new size of files modified:  $mkvSizeNewTotalGB" | Out-File $LogFile -append
    Write-Output "Size saved:  $TotalSaved" | Out-File $LogFile -append
}


# Dump files to be deleted to a log file for possible use later.
Write-Output ($DeleteOrig) | Out-File $mkvOriginals -Append

Write-Host "The original files list can be found here:  $($mkvOriginals), do you want to nuke these?" -ForegroundColor Red


If ($Answer3 -eq 0) {
    
    Write-Output "The option to delete original files was selected." | Out-File $LogFile -append
    Write-Host "Deleteing original files..." -ForegroundColor DarkRed
    $DeleteOrig | Remove-Item

}


Write-Host "Script complete!" -ForegroundColor Cyan
Write-Host "You can find logs in the following location:  $($Destination)" -ForegroundColor Green

Write-Output "Script completed on $(Get-Date -UFormat "%m-%d-%Y %r")" | Out-File $LogFile -append
Write-Output "##################################################" | Out-File $LogFile -append

# eos