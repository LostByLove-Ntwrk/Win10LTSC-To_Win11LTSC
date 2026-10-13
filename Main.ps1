[CmdletBinding()]
# Change path and to your path and setup.exe to the the ISO that is used
param (
    [string]$SetupExe = "C:\Path\To\Windows11\setup.exe",
    [string]$LogPath = "$env:SystemRoot\Logs\Windows11Upgrade"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting Windows 11 upgrade..."
Write-Host "Creating Log Folder and checking Setup Path"

#-------------------
# Create Log Folder
#-------------------

if (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

#--------------------------
# Verify Setup Path Exists
#--------------------------

if (!(Test-Path $SetupExe)) {
    Write-Host "[ERROR] setup.exe not found."
    exit 1
} else { 
    Write-Host "Path correct moving onto Disk Space Check"
}
#------------------------
# Basic Disk Space Check
#------------------------

$drive = Get-PSDrive -Name C
if ($drive.Free -lt 64GB) {
    Write-Host "[ERROR] Not enough free disk space minimum 64GB required."
    exit 1
} else { 
    Write-Host "Moving to Start Upgrade"
}

#------------------------------------------------------------------
# Setup Arguments         "/pkey", (add own product key)
#------------------------------------------------------------------

$args = @(
    "/auto", "upgrade",
    "/imageindex", "1",
    "/quiet",
    "/eula", "accept",
    "/dynamicupdate", "disable",
    "/copylogs", $LogPath,
    "/migratedrivers", "all",
    "/noreboot"
    # Uncomment the line below if you need to pass a product key check during upgrade:
    # , "/pkey", "YOUR-PRODUCT-KEY-HERE"
)

#---------------
# Start Upgrade
#---------------

Write-Host "Launching upgrade..."

$proc = Start-Process -FilePath $SetupExe -ArgumentList $args -Wait -PassThru

Write-Host "Logs stored in: $LogPath"

#----------------
# Popup for USER
#----------------
    $taskName = "WindowsUpgradeRestartPrompt"
    $scriptPath = "$env:ProgramData\UpgradePrompt.ps1"
    
#----------------------------------
# This script runs in USER Session
#----------------------------------

    @'
$mutex = New-Object System.Threading.Mutex($false, "WindowsUpgradeRestartPrompt")
if (-not $mutex.WaitOne(0)) { 
  exit 
}

Add-Type -AssemblyName PresentationFramework

$attempt = 1

while ($true) {

    # First 2 prompts = Yes/No
    
    if ($attempt -lt 3) {

        $result = [System.Windows.MessageBox]::Show(
            "De Windows upgrade is klaar. Gelieve te herstarten om te vervolledigen.`n`nBest eerst alles op te slagen voor het herstarten.`n`nNu herstarten?`n`n(Poging $attempt van 3)",
            "Restart Required",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )

        # User clicked Yes
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            schtasks /Delete /TN "WindowsUpgradeRestartPrompt" /F | Out-Null
            Restart-Computer -Force
            break
        }

        # User clicked No
        $attempt++
        Start-Sleep -Seconds 900
    }

    # Third prompt = only Yes button
   
    else {

        [System.Windows.MessageBox]::Show(
            "De Windows upgrade moet nu worden voltooid.`n`nDe computer zal herstarten.",
            "Restart Required",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )

        schtasks /Delete /TN "WindowsUpgradeRestartPrompt" /F | Out-Null
        Restart-Computer -Force
        break
    }
}

$mutex.ReleaseMutex()

'@ | Set-Content -Path $scriptPath -Encoding UTF8

#-------------------
# Run at USER LOGON
#-------------------

$currentUser = (Get-CimInstance Win32_ComputerSystem).UserName

#------------------------------
# Create scheduled task action
#------------------------------

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -AtLogOn

$principal = New-ScheduledTaskPrincipal `
    -UserId $currentUser `
    -LogonType Interactive `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Force | Out-Null

#---------------------------
# Launch popup if Logged in
#---------------------------

Start-ScheduledTask -TaskName $taskName

    Write-Host "Restart prompt deployed to user session."