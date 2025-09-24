# tfrun Windows PowerShell installer
# Usage: iwr -useb https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.ps1 | iex

param(
    [string]$InstallDir = "$env:USERPROFILE\bin",
    [string]$Version = "",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Colors
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Info {
    param([string]$Message)
    Write-Host "${Blue}[INFO]${Reset} $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "${Green}[SUCCESS]${Reset} $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "${Yellow}[WARNING]${Reset} $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "${Red}[ERROR]${Reset} $Message"
}

if ($Help) {
    Write-Host "tfrun Windows installer"
    Write-Host ""
    Write-Host "Usage: iwr -useb https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.ps1 | iex"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -InstallDir DIR   Install directory (default: %USERPROFILE%\bin)"
    Write-Host "  -Version VER      Specific version to install (default: latest)"
    Write-Host "  -Help             Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  # Install to default location"
    Write-Host "  iwr -useb https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.ps1 | iex"
    Write-Host ""
    Write-Host "  # Install to custom directory"
    Write-Host "  iwr -useb https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.ps1 | iex -InstallDir 'C:\tools'"
    exit 0
}

function Get-LatestVersion {
    $apiUrl = "https://api.github.com/repos/rajamohan-rj/tfrun/releases/latest"
    try {
        $response = Invoke-RestMethod -Uri $apiUrl
        return $response.tag_name
    }
    catch {
        Write-Error "Failed to get latest version: $_"
        exit 1
    }
}

function Install-Tfrun {
    Write-Host "🚀 tfrun Windows installer"
    Write-Host ""
    
    Write-Info "Installing tfrun..."
    
    # Get version
    if (-not $Version) {
        $Version = Get-LatestVersion
        Write-Info "Latest version: $Version"
    }
    else {
        Write-Info "Installing version: $Version"
    }
    
    # Remove 'v' prefix for filename
    $versionNumber = $Version -replace '^v', ''
    
    # Construct download URL
    $filename = "tfrun_${versionNumber}_Windows_x86_64.tar.gz"
    $downloadUrl = "https://github.com/rajamohan-rj/tfrun/releases/download/${Version}/${filename}"
    
    Write-Info "Downloading from: $downloadUrl"
    
    # Create temporary directory
    $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
    $archivePath = Join-Path $tempDir $filename
    
    # Download
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath
    }
    catch {
        Write-Error "Failed to download $filename : $_"
        exit 1
    }
    
    # Extract (requires tar on Windows 10+)
    Write-Info "Extracting archive..."
    try {
        tar -xzf $archivePath -C $tempDir
    }
    catch {
        Write-Error "Failed to extract archive. Make sure you have tar available (Windows 10+ or Git for Windows)"
        exit 1
    }
    
    # Create install directory
    if (-not (Test-Path $InstallDir)) {
        Write-Info "Creating install directory: $InstallDir"
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    
    # Install binary
    $binaryPath = Join-Path $tempDir "tfrun.exe"
    $installPath = Join-Path $InstallDir "tfrun.exe"
    
    Write-Info "Installing to: $installPath"
    
    try {
        Copy-Item $binaryPath $installPath -Force
    }
    catch {
        Write-Error "Failed to install binary: $_"
        exit 1
    }
    
    # Cleanup
    Remove-Item $tempDir -Recurse -Force
    
    Write-Success "tfrun $Version installed successfully!"
    
    # Check if in PATH
    $pathDirs = $env:PATH -split ';'
    if ($InstallDir -in $pathDirs) {
        Write-Success "tfrun is now available in your PATH"
        $version = & $installPath --version
        Write-Info "Version: $version"
    }
    else {
        Write-Warning "tfrun installed to $installPath but directory not in PATH"
        Write-Warning "Add $InstallDir to your PATH environment variable"
    }
    
    Write-Host ""
    Write-Info "Usage: tfrun --help"
    Write-Host ""
    Write-Success "Installation complete! 🎉"
}

# Run installation
Install-Tfrun
