$ErrorActionPreference = "Stop"

$Repo = "Geyvra/GevyraCLI"
$Asset = "Gevyra-windows-amd64.exe"
$InstallDir = Join-Path $env:LOCALAPPDATA "Gevyra\bin"
$BinaryName = "gevyra.exe"

Write-Host "Installing Gevyra CLI..." -ForegroundColor Cyan

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "Error: PowerShell 5 or newer is required." -ForegroundColor Red
    exit 1
}

# GitHub download URL
$DownloadUrl = "https://github.com/$Repo/releases/latest/download/$Asset"

Write-Host "Downloading Gevyra CLI..." -ForegroundColor Cyan

# Create installation directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$TargetPath = Join-Path $InstallDir $BinaryName

# Download
Invoke-WebRequest `
    -Uri $DownloadUrl `
    -OutFile $TargetPath `
    -UseBasicParsing

# Add installation directory to user PATH
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

$PathEntries = @()

if (-not [string]::IsNullOrWhiteSpace($UserPath)) {
    $PathEntries = $UserPath -split ";" | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }
}

if ($PathEntries -notcontains $InstallDir) {
    if ([string]::IsNullOrWhiteSpace($UserPath)) {
        $NewUserPath = $InstallDir
    }
    else {
        $NewUserPath = "$UserPath;$InstallDir"
    }

    [Environment]::SetEnvironmentVariable(
        "Path",
        $NewUserPath,
        "User"
    )

    # Update current PowerShell session
    $env:Path = "$env:Path;$InstallDir"
}

Write-Host ""
Write-Host "GeVyra CLI installed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Run:"
Write-Host "  gevyra --help"
Write-Host ""

# Verify installation
if (Test-Path $TargetPath) {
    Write-Host "Installation path:"
    Write-Host "  $TargetPath"

    try {
        Write-Host ""
        Write-Host "Version:"
        & $TargetPath --version
    }
    catch {
        # Ignore if --version is not implemented yet
    }
}
else {
    Write-Host "Installation failed." -ForegroundColor Red
    exit 1
}