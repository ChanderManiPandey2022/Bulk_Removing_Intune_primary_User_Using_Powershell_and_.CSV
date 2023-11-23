﻿ # <Remove  Inutne Primary User Using PowerShell>
#.DESCRIPTION
 # <Remove Inutne Primary User Using PowerShell>
#.Demo
#<YouTube video link-->https://www.youtube.com/@ChanderManiPandey
#.INPUTS
 # <Provide all required inforamtion in User Input Section-line No 29-30>
#.OUTPUTS
 # <This will  Remove  Primary in Intune portal>
#.NOTES
 <# Version:       1.0
  Author:          Chander Mani Pandey
  Creation Date:   23 Nov 2023
  
  Find Author on 
  Youtube:-         https://www.youtube.com/@chandermanipandey8763
  Twitter:-           https://twitter.com/Mani_CMPandey
  LinkedIn:-         https://www.linkedin.com/in/chandermanipandey
   #>

cls
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' 
$error.clear() ## this is the clear error history 

# ==============================User Input Section Start=============================================================================================================
$Path = "C:\Temp\IntuneReporting\ChangePrimaryUser"
$FilePath = "C:\TEMP\InputFile.csv"
# ==============================User Input Section End===============================================================================================================



$Inputfile = Import-Csv -Path $FilePath
$LogPath = Join-Path -Path $Path -ChildPath "ChangePrimaryUser.txt"

# Check if the log directory exists; if not, create it
if (-not (Test-Path -Path $Path)) {
    New-Item -Path $Path -ItemType Directory -Force
}

# Check if the log file exists; if not, create it
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType File
}

# Function to write log messages to the log file
function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    
    $FormattedLog = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $FormattedLog -ForegroundColor $Color
    $FormattedLog | Out-File -FilePath $LogPath -Append
}

# Log the script start
Write-Log -Message "Script started" -Color "White"

# Install and import the Microsoft.Graph.Intune module if not already installed
$MGIModule = Get-Module -Name "Microsoft.Graph.Intune" -ListAvailable
if ($MGIModule -eq $null) {
    Install-Module -Name Microsoft.Graph.Intune -Force
}
Import-Module Microsoft.Graph.Intune -Force

# Connect to Microsoft Graph
Connect-MSGraph
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet
Connect-MSGraph -Quiet

# Get the total number of devices in the CSV file
$totalDevices = $Inputfile.Count
Write-Log -Message "Total devices in CSV: $totalDevices" -Color "White"
Write-Host ""

# Initialize a counter for device progress
$deviceCounter = 0

foreach ($In in $Inputfile) {
    $deviceCounter++
    
    # Check and skip the update if they are the same
    if ($In.NewUserName -eq $In.userPrincipalName) {
        $message = "Skipping update for $deviceCounter/$totalDevices devices"
        Write-Host $message -ForegroundColor Yellow
        Write-Log -Message $message -Color "Green"
        Write-Host "==============================================================================================================================================================="
        continue
    }

    $message = "Updating $deviceCounter/$totalDevices devices - New Primary User Name:- None ..."  
    Write-Host $message -ForegroundColor Yellow
    Write-Log -Message $message -ForegroundColor Yellow

     $graphApiVersion = "beta"
     $Resource = "deviceManagement/managedDevices('$($In.id)')/users/`$ref"
     $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
     $userUri = "https://graph.microsoft.com/$graphApiVersion/users/" + $($In.NewUserID)
     $JSON = @{
         "@odata.id" = $userUri
     }
    
     try {
         Invoke-MSGraphRequest -HttpMethod DELETE -Url $uri -Content $JSON
         $successMessage = "Successfully updated the primary user."
        # Write-Host $successMessage -ForegroundColor Green
         Write-Log -Message $successMessage -Color "Green"
         Write-Host "============================================================================================================================================================="
     } catch {
         $errorMessage = "An error occurred: $_"
         Write-Host $errorMessage
         Write-Log -Message $errorMessage -Color "Red"
         if ($_.ErrorDetails) {
             $errorDetails = "Error Details:`n$($_.ErrorDetails)"
             Write-Host $errorDetails
             Write-Log -Message $errorDetails -Color "Red"
         }
     }
}

# Log the script completion
Write-Log -Message "Script completed" -Color "White"
