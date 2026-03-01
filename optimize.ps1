# List of PowerShell scripts to run
$urls = @(
    "https://raw.githubusercontent.com/ostwrafi/installer/refs/heads/main/installop.ps1",
    "https://christitus.com/win"
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
        break   # stops execution if one fails
    }
}
