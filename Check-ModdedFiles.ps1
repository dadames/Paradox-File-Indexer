$StellarisLocation = "C:\Program Files (x86)\Steam\steamapps\common\Stellaris\"

$HashFileSaveLocation = "$pwd\Hashes\"
$HashFileName = "Hashes-$(get-date -f yyyy-MM-dd-HH-mm-ss).txt"

$FileChangelogLocation = $pwd
$FileChangelogName = "changelog.txt"
$FileChangelogFull = "$FileChangelogLocation\$FileChangelogName"

$ModOverwriteIndexFolder = "$pwd\File Overwrites\"
$IndexesOutput = "$pwd\ChangedModFiles.txt"


#Functions and Params
function Show-Menu
{
    param (
        [string]$Title = 'My Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Index Current Patch"
    Write-Host "2: Compare most recent 2 patches"
    Write-Host "3: Check FileChangelog against FileOverwrites"
    Write-Host "Q: Press 'Q' to quit."
}

filter leftside{
param(
        [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $obj
    )

    $obj|?{$_.sideindicator -eq '<='}
}


##########################
# 1. Index Current Patch #
##########################

function GetHashes {
    $PatchNumber = Read-Host "What patch number is being indexed?"
    if ([String]::IsNullOrEmpty($PatchNumber)) {
        
    }
    else {
        $script:HashFileName = "$PatchNumber.txt"
    }

    Get-ChildItem "$StellarisLocation\common" -Recurse | 
        Get-FileHash | Select-Object Path,Hash | 
            Export-Csv "$HashFileSaveLocation$HashFileName" -NoTypeInformation
}




######################
# 2. Compare Patches #
######################

function ComparePatches {
    #Import Index Files
    if ((Get-ChildItem $HashFileSaveLocation -File | Measure-Object).Count -lt 2){
        do {
            $script:Response = Read-Host -Prompt "There are less than 2 index files to compare. Do you want to perform an index for the current path[y/N]"
            if ($response -eq 'y') {
                GetHashes
            }
        } until ($response -eq 'n' -or ((Get-ChildItem $HashFileSaveLocation -File | Measure-Object).Count -gt 1))
    }
    $OldHashFile = gci $HashFileSaveLocation | select -skip 1 -last 1 | % { $_.FullName }
    $NewHashFile = gci $HashFileSaveLocation | select -last 1 | % { $_.FullName }

    #Difference Files
    Compare-Object -ReferenceObject (Get-Content -Path $OldHashFile) -DifferenceObject (Get-Content -Path $NewHashFile) | 
        leftside | 
            Select InputObject |
                Export-Csv "$FileChangelogLocation\$FileChangelogName" -NoTypeInformation

    #Cleanup output
    ((gc $FileChangelogFull) -replace '"',''| select -Skip 1) | sc $FileChangelogFull

    @('"Path","Hash"') + (gc $FileChangelogFull) | sc $FileChangelogFull

    (Import-Csv $FileChangelogFull)| Select "Path" | Export-Csv $FileChangelogFull -NoTypeInformation

    ((gc $FileChangelogFull) -replace '"',''| select -Skip 1) | sc $FileChangelogFull


    (gc $FileChangelogFull) -replace  [regex]::Escape($StellarisLocation), '' | sc $FileChangelogFull
}


##########################################
# 3. Compare Changelog to Mod Overwrites #
##########################################

function CompareModOverwrites {
    #Import Index Files
    foreach ($Index in (Get-ChildItem $ModOverwriteIndexFolder)) {
        Compare-Object -ReferenceObject (Get-Content -Path $Index.FullName) -DifferenceObject (Get-Content -Path $FileChangelogFull) -IncludeEqual -ExcludeDifferent | 
                Select InputObject |
                    Export-Csv "$IndexesOutput" -NoTypeInformation
        ((gc $IndexesOutput) -replace '"',''| select -Skip 1) | sc $IndexesOutput
    }
}




Show-Menu -Title "Stellaris Modded Files Index and Compare"
    $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
             GetHashes
         } '2' {
             ComparePatches
         } '3' {
             CompareModOverwrites
         } 'q' {
             return
         }
     }
