<#

Script Name:  auto_mkvmerge.ps1
By:  Zack Thompson / Created:  3/19/2017
Version:  .5 / Updated:  3/22/2017 / By:  ZT

Description:  This script will allow for batch processing of files with the mkvmerge.exe tool.

Note:  This script is 'working' as desired, but by no means is finished -- more to come.

#>

Write-Host "This script will allow for batch processing of files with the mkvmerge.exe tool."

# Define $LineFeed
$LineFeed = [char]0x000A
$Delete = '!'

# Define text that needs be trimmed from the output of mkvinfo.exe.
$Trims = @{}
$Trims.'|  + ' = ''
$Trims.'Track number: ' = '!'
$Trims.' (track ID for mkvmerge & mkvextract: ' = ':'
$Trims.')' = ''
$Trims.'Track type: ' = ''
$Trims.'Language: ' = ''
$Trims."$($LineFeed)" = ','

Write-Host ""
Write-Host ""

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

# Location of files to scan (change:  request from user)
# $Location = Read-Host "Please provide location to scan for files"
Set-Location "M:\Library\TV\Silicon Valley\Season 1\test"  # For testing phase.

# Get all mkvs info from provided location
$mkvs = Get-ChildItem *.mkv | Select Name, Directory

# Declare Array
$mkvInfoResults = @()
$mkvObject = @()

ForEach ($mkv in $mkvs) {

    # Get data from mkvs with mkvinfo.exe.
    $mkvInfo = cmd /c mkvinfo.exe $mkv.Name | Where-Object -FilterScript { ($_ -like '*Track number*') -or ($_ -like '*Track type*') -or ($_ -like '*Language*') -and ($_ -notlike '*Chapter*') } | Out-String

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
        }

        # Add hash table to custom object
        $mkvObject += New-Object PSObject -Property $mkvProperties

    }
}

# Display results to screen for review
Write-Host "All tracks for provided files, please review before continuing..."
$mkvObject | Select-Object Track, Type, Language, Name |  FT

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

    Write-Host "The following number of changes will be made per file:  (Last point to turn back!)"
    $mkvItems | Select-Object Count, Name | FT -AutoSize
}


If ($mkvItems.Count -lt '1') {
    Write-Host "Nothing to edit in provided directory!"
}
Else {
    # Function Question2
    Question2

    If ($Answer2 -eq 0) {

        # Performing the changes...
        Write-Host "No turning back now..."
        Write-Host "No worries, no changes to the original files will be made yet!  :)"
        Write-Host " "

        # Define Array
        $DeleteOrig = @()

        ForEach ($mkvItem in $mkvItems) {

            # Get all the audio tracks to be removed, and deliminate the with commas.
            $mkvAudios = ($mkvItem.Group | Where-Object { $_.Type -eq "audio" } | Select-Object -ExpandProperty Track) -join ','

            # Get all the subtitle tracks to be removed, and deliminate the with commas.
            $mkvSubtitles = ($mkvItem.Group | Where-Object { $_.Type -eq "subtitles" } | Select-Object -ExpandProperty Track) -join ','

            # Define Input and Output file names.
            $InputFile = $mkvItem.Name
            $OutputFile = "new_" + $mkvItem.Name

            # Perform mkvmerge on file.
            #Write-Host "mkvmerge.exe --output $OutputFile --audio-tracks $($Delete)$($mkvAudios) --subtitle-tracks $($Delete)$($mkvSubtitles) $InputFile"
            mkvmerge.exe --output $OutputFile --audio-tracks "$($Delete)$($mkvAudios)" --subtitle-tracks "$($Delete)$($mkvSubtitles)" $InputFile

            # Perform mkvpropedit on file.
            #Write-Host "mkvpropedit.exe $OutputFile --delete title"
            mkvpropedit.exe $OutputFile --delete title
 
            # Label original as such.
            Rename-Item $InputFile -NewName "orig_$($InputFile)"
            $DeleteOrig += "orig_$($InputFile)"

            # Rename 'new' as 'production.'
            Rename-Item $OutputFile -NewName $InputFile
        }
    }

    Write-Host "Here are the original files, do you want to nuke these?"
    $DeleteOrig

    # Function Question3
    Question3

    If ($Answer3 -eq 0) {

        $DeleteOrig | Remove-Item

    }
}