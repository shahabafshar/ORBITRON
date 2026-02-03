# ORBITRON launcher for Windows
# Runs the Bash menu via Git Bash or WSL. Requires one of them to be installed.

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Prefer Git Bash (common on Windows with Git for Windows)
$bashPaths = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
)

$bash = $null
foreach ($p in $bashPaths) {
    if (Test-Path $p) {
        $bash = $p
        break
    }
}

if ($bash) {
    & $bash -l -c "cd '$($scriptDir -replace "'", "'\'''")' && ./main.sh"
    exit $LASTEXITCODE
}

# Fallback: wsl if available
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    wsl bash -c "cd '$($scriptDir -replace '\', '/')' && ./main.sh"
    exit $LASTEXITCODE
}

Write-Host "ORBITRON requires Bash. Install one of:" -ForegroundColor Red
Write-Host "  - Git for Windows (https://git-scm.com/download/win) then run: bash main.sh" -ForegroundColor Yellow
Write-Host "  - WSL (Windows Subsystem for Linux) then run: wsl bash main.sh" -ForegroundColor Yellow
exit 1
