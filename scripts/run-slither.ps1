# Run Slither on Windows when `slither` is not in PATH (pip installs to Python Scripts).
Set-Location $PSScriptRoot\..

Write-Host "Running Slither via python -m slither ..."
python -m slither . --filter-paths "lib|test/security"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Slither finished with findings or errors (exit $LASTEXITCODE)."
    exit $LASTEXITCODE
}

Write-Host "Done."
