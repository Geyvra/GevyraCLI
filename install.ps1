$ErrorActionPreference = "Stop"

$Repo = "Geyvra/GevyraCLI"
$Asset = "Gevyra-windows-amd64.exe"
$InstallDir = Join-Path $env:LOCALAPPDATA "Gevyra\bin"
$BinaryName = "gevyra.exe"
$TargetPath = Join-Path $InstallDir $BinaryName

Write-Host "Gevyra CLI installer" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------------
# Check PowerShell version
# --------------------------------------------------

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "Error: PowerShell 5 or newer is required." -ForegroundColor Red
    exit 1
}

# --------------------------------------------------
# Ensure installation directory exists
# --------------------------------------------------

if (-not (Test-Path $InstallDir)) {
    Write-Host "Creating installation directory..." -ForegroundColor Cyan

    New-Item `
        -ItemType Directory `
        -Path $InstallDir `
        -Force | Out-Null
}

# --------------------------------------------------
# Check if Gevyra CLI is already installed
# --------------------------------------------------

$AlreadyInstalled = Test-Path $TargetPath

if ($AlreadyInstalled) {
    Write-Host "Gevyra CLI is already installed." -ForegroundColor Yellow
    Write-Host "Location: $TargetPath" -ForegroundColor DarkGray
    Write-Host ""

    try {
        Write-Host "Current version:" -ForegroundColor Cyan
        & $TargetPath --version
    }
    catch {
        Write-Host "Unable to determine current version." -ForegroundColor DarkYellow
    }

    Write-Host ""
    Write-Host "Updating Gevyra CLI..." -ForegroundColor Cyan
}
else {
    Write-Host "Gevyra CLI is not installed." -ForegroundColor Yellow
    Write-Host "Installing Gevyra CLI..." -ForegroundColor Cyan
}

# --------------------------------------------------
# GitHub download URL
# --------------------------------------------------

$DownloadUrl = "https://github.com/$Repo/releases/latest/download/$Asset"

Write-Host ""
Write-Host "Downloading Gevyra CLI..." -ForegroundColor Cyan
Write-Host "  $DownloadUrl" -ForegroundColor DarkGray

# --------------------------------------------------
# Download binary
# --------------------------------------------------

try {
    Invoke-WebRequest `
        -Uri $DownloadUrl `
        -OutFile $TargetPath `
        -UseBasicParsing
}
catch {
    Write-Host ""
    Write-Host "Failed to download Gevyra CLI." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# --------------------------------------------------
# Configure user PATH
# --------------------------------------------------

Write-Host ""
Write-Host "Configuring PATH..." -ForegroundColor Cyan

$UserPath = [Environment]::GetEnvironmentVariable(
    "Path",
    "User"
)

if ([string]::IsNullOrWhiteSpace($UserPath)) {
    $PathEntries = @()
}
else {
    $PathEntries = $UserPath -split ";" |
        Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        } |
        ForEach-Object {
            $_.TrimEnd("\")
        }
}

$NormalizedInstallDir = $InstallDir.TrimEnd("\")

# Case-insensitive PATH check
$PathAlreadyExists = $PathEntries |
    Where-Object {
        $_ -ieq $NormalizedInstallDir
    }

if (-not $PathAlreadyExists) {

    if ($PathEntries.Count -eq 0) {
        $NewUserPath = $NormalizedInstallDir
    }
    else {
        $NewUserPath = ($PathEntries + $NormalizedInstallDir) -join ";"
    }

    [Environment]::SetEnvironmentVariable(
        "Path",
        $NewUserPath,
        "User"
    )

    Write-Host "Added Gevyra to user PATH." -ForegroundColor Green
}
else {
    Write-Host "Gevyra is already present in user PATH." -ForegroundColor Green
}

# --------------------------------------------------
# Update current PowerShell session PATH
# --------------------------------------------------

$MachinePath = [Environment]::GetEnvironmentVariable(
    "Path",
    "Machine"
)

$CurrentUserPath = [Environment]::GetEnvironmentVariable(
    "Path",
    "User"
)

$env:Path = "$MachinePath;$CurrentUserPath"

# --------------------------------------------------
# Verify installation
# --------------------------------------------------

Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Cyan

if (-not (Test-Path $TargetPath)) {
    Write-Host "Installation failed: binary was not found." -ForegroundColor Red
    exit 1
}

Write-Host "Binary found:" -ForegroundColor Green
Write-Host "  $TargetPath"

# Check if command is accessible through PATH
$GevyraCommand = Get-Command gevyra -ErrorAction SilentlyContinue

if ($null -eq $GevyraCommand) {
    Write-Host ""
    Write-Host "Warning: Gevyra was installed but is not currently accessible through PATH." -ForegroundColor Yellow
    Write-Host "You may need to restart PowerShell." -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "Gevyra command is available through PATH." -ForegroundColor Green
    Write-Host "  $($GevyraCommand.Source)"
}

# --------------------------------------------------
# Version
# --------------------------------------------------

Write-Host ""
Write-Host "Version:" -ForegroundColor Cyan

try {
    & $TargetPath --version
}
catch {
    Write-Host "The CLI does not expose --version yet." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "Gevyra CLI installed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Run:" -ForegroundColor Cyan
Write-Host "  gevyra --help"
Write-Host ""