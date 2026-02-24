# List of PowerShell scripts to run
$urls = @(
    "https://raw.githubusercontent.com/ostwrafi/installer/refs/heads/main/deploy.ps1",
    "https://raw.githubusercontent.com/ostwrafi/installer/refs/heads/main/managment.ps1"
)

foreach ($url in $urls) {
    Write-Host "Running $url..." -ForegroundColor Cyan

    try {
        irm $url -ErrorAction Stop | iex
        Write-Host "✔ Success: $url" -ForegroundColor Green
    }
    catch {
        Write-Host "✖ Failed: $url" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
        break   
    }
}
