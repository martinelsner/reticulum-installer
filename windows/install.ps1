#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Reticulum + LXMF Installer for Windows

.DESCRIPTION
    Installs rnsd and lxmd as Windows Services with default
    configurations and a dedicated data directory.

.NOTES
    Usage: Run as Administrator
        powershell -ExecutionPolicy Bypass -File install.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DataDir    = "$env:ProgramData\Reticulum"
$VenvDir    = "$env:ProgramFiles\Reticulum"
$NssmDir    = "$env:ProgramFiles\Reticulum\nssm"
$NssmExe    = "$NssmDir\nssm.exe"
$NssmVersion = "2.24"
$NssmZipUrl = "https://nssm.cc/release/nssm-$NssmVersion.zip"

# ---------- Preflight ----------

Write-Host "==> Reticulum + LXMF Installer (Windows)" -ForegroundColor Cyan
Write-Host ""

# ---------- Dependencies ----------

Write-Host "--- Installing dependencies ---"

# Check for Python
Write-Host "    Checking for Python..."
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "    Python not in PATH. Checking common locations..."
    
    # Check common installation paths
    $commonPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312",
        "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts",
        "$env:ProgramFiles\Python312",
        "$env:ProgramFiles\Python312\Scripts",
        "C:\Python312",
        "C:\Python312\Scripts"
    )
    foreach ($path in $commonPaths) {
        $pythonExe = Join-Path $path "python.exe"
        if (Test-Path $pythonExe) {
            Write-Host "    Found Python at: $pythonExe"
            $env:Path = "$path;" + $env:Path
            $python = Get-Command $pythonExe -ErrorAction SilentlyContinue
            break
        }
    }
    
    # If still not found, try winget
    if (-not $python) {
        Write-Host "    Attempting to install Python via winget..."
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $wingetCmd) {
            Write-Host "    ERROR: winget not found. Cannot install Python automatically."
            Write-Host "    Please install Python manually and add to PATH."
            exit 1
        }
        winget install --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements --silent
        # Refresh PATH from machine and user registry
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = "$machinePath;$userPath"
        # Re-check Python
        $python = Get-Command python -ErrorAction SilentlyContinue
    }
    
    if (-not $python) {
        Write-Host "    ERROR: Python installation failed or not in PATH."
        exit 1
    }
}
Write-Host "    Python: $($python.Source)"

# ---------- Virtual Environment ----------

Write-Host ""
Write-Host "--- Setting up Python virtual environment ---"

# Use the Python we found earlier (with explicit path if needed)
$pythonCmd = If ($python.Source) { $python.Source } else { "python" }

if (-not (Test-Path "$VenvDir\Scripts\python.exe")) {
    Write-Host "    Creating virtualenv at $VenvDir..."
    New-Item -ItemType Directory -Path $VenvDir -Force | Out-Null
    
    try {
        & cmd /c "$pythonCmd -m venv $VenvDir"
        if ($LASTEXITCODE -ne 0) {
            throw "venv creation failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Host "    ERROR: Failed to create virtualenv: $_"
        Write-Host "    Attempting fallback method..."
        # Fallback: try using py launcher
        & py -3.12 -m venv $VenvDir
    }
    
    # Verify venv was created properly
    if (Test-Path "$VenvDir\Scripts\python.exe") {
        Write-Host "    Created virtualenv at $VenvDir"
    } else {
        Write-Host "    ERROR: Virtualenv created but python.exe not found in Scripts folder."
        Write-Host "    Contents of Reticulum folder:"
        Get-ChildItem $VenvDir | ForEach-Object { Write-Host "        $($_.Name)" }
        exit 1
    }
} else {
    Write-Host "    Virtualenv already exists at $VenvDir"
}

Write-Host "    Installing Python packages..."
Write-Host "    Checking pip availability..."
if (-not (Test-Path "$VenvDir\Scripts\pip.exe")) {
    Write-Host "    ERROR: pip.exe not found in virtualenv"
    Write-Host "    Contents of Scripts folder:"
    Get-ChildItem "$VenvDir\Scripts" | ForEach-Object { Write-Host "        $($_.Name)" }
    exit 1
}
& "$VenvDir\Scripts\pip.exe" install --quiet rns lxmf
if ($LASTEXITCODE -ne 0) {
    Write-Host "    WARNING: pip install may have failed, continuing..."
}

# ---------- NSSM (service manager) ----------

Write-Host ""
Write-Host "--- Installing NSSM (service manager) ---"

if (-not (Test-Path $NssmExe)) {
    $nssmZip = "$env:TEMP\nssm.zip"
    $nssmExtract = "$env:TEMP\nssm-extract"

    Write-Host "    Downloading NSSM $NssmVersion..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $NssmZipUrl -OutFile $nssmZip -UseBasicParsing

    Write-Host "    Extracting..."
    Expand-Archive -Path $nssmZip -DestinationPath $nssmExtract -Force

    New-Item -ItemType Directory -Path $NssmDir -Force | Out-Null
    Copy-Item "$nssmExtract\nssm-$NssmVersion\win64\nssm.exe" $NssmExe -Force

    Remove-Item $nssmZip -Force -ErrorAction SilentlyContinue
    Remove-Item $nssmExtract -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "    NSSM installed to $NssmExe"
} else {
    Write-Host "    NSSM already installed."
}

# ---------- Configuration ----------

Write-Host ""
Write-Host "--- Installing configuration files ---"

function Install-Config {
    param([string]$Source, [string]$Destination)

    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if (Test-Path $Destination) {
        Write-Host "    SKIP $Destination (already exists, not overwriting)"
    } else {
        Copy-Item $Source $Destination
        Write-Host "    Installed $Destination"
    }
}

Install-Config "$ScriptDir\..\config\rnsd.config" "$DataDir\rnsd\config"
Install-Config "$ScriptDir\..\config\lxmd.config"  "$DataDir\lxmd\config"

# ---------- Windows Services ----------

Write-Host ""
Write-Host "--- Installing Windows Services ---"

$rnsdExe  = "$VenvDir\Scripts\rnsd.exe"
$lxmdExe  = "$VenvDir\Scripts\lxmd.exe"

# rnsd service
$svc = Get-Service -Name "rnsd" -ErrorAction SilentlyContinue
if (-not $svc) {
    & $NssmExe install rnsd $rnsdExe --config "$DataDir\rnsd"
    & $NssmExe set rnsd DisplayName "Reticulum Network Stack Daemon"
    & $NssmExe set rnsd Description "Routes traffic for the Reticulum Network Stack."
    & $NssmExe set rnsd Start SERVICE_AUTO_START
    & $NssmExe set rnsd AppStdout "$DataDir\rnsd\service.log"
    & $NssmExe set rnsd AppStderr "$DataDir\rnsd\service.log"
    & $NssmExe set rnsd AppRotateFiles 1
    & $NssmExe set rnsd AppRotateBytes 1048576
    Write-Host "    Installed rnsd service."
} else {
    Write-Host "    rnsd service already exists."
}

# lxmd service
$svc = Get-Service -Name "lxmd" -ErrorAction SilentlyContinue
if (-not $svc) {
    & $NssmExe install lxmd $lxmdExe --config "$DataDir\lxmd" --rnsconfig "$DataDir\rnsd"
    & $NssmExe set lxmd DisplayName "LXMF Router Daemon"
    & $NssmExe set lxmd Description "Routes messages for the LXMF messaging layer."
    & $NssmExe set lxmd Start SERVICE_AUTO_START
    & $NssmExe set lxmd DependOnService rnsd
    & $NssmExe set lxmd AppStdout "$DataDir\lxmd\service.log"
    & $NssmExe set lxmd AppStderr "$DataDir\lxmd\service.log"
    & $NssmExe set lxmd AppRotateFiles 1
    & $NssmExe set lxmd AppRotateBytes 1048576
    Write-Host "    Installed lxmd service."
} else {
    Write-Host "    lxmd service already exists."
}

# ---------- Start Services ----------

Write-Host ""
Write-Host "--- Starting services ---"

Start-Service rnsd
Write-Host "    rnsd: started."

Start-Service lxmd
Write-Host "    lxmd: started."

# ---------- Firewall Rules ----------

Write-Host ""
Write-Host "--- Configuring firewall ---"

$fwRnsd = Get-NetFirewallRule -DisplayName "Reticulum rnsd" -ErrorAction SilentlyContinue
if (-not $fwRnsd) {
    New-NetFirewallRule -DisplayName "Reticulum rnsd" `
        -Direction Inbound -Protocol TCP -LocalPort 4242 `
        -Action Allow -Profile Any | Out-Null
    Write-Host "    Firewall rule added for rnsd (TCP 4242)."
} else {
    Write-Host "    Firewall rule for rnsd already exists."
}

# ---------- Summary ----------

Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Services:"
Write-Host "    rnsd  -> Get-Service rnsd"
Write-Host "    lxmd  -> Get-Service lxmd"
Write-Host ""
Write-Host "  Configuration:"
Write-Host "    rnsd  -> $DataDir\rnsd\config"
Write-Host "    lxmd  -> $DataDir\lxmd\config"
Write-Host ""
Write-Host "  Logs:"
Write-Host "    rnsd  -> $DataDir\rnsd\service.log"
Write-Host "    lxmd  -> $DataDir\lxmd\service.log"
Write-Host ""
Write-Host "  To reconfigure, edit the config files and run:"
Write-Host "    Restart-Service rnsd, lxmd"
Write-Host ""
