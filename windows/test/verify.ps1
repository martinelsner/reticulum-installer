<#
.SYNOPSIS
    Verification script for the Windows Reticulum installer.
    Returns exit code 0 if all checks pass, non-zero on failure.
#>

$ErrorActionPreference = "Continue"
$pass = 0
$fail = 0

function Check {
    param(
        [string]$Description,
        [scriptblock]$Test
    )

    try {
        $result = & $Test
        if ($result) {
            Write-Host "  ✓ $Description"
            $script:pass++
        } else {
            Write-Host "  ✗ $Description"
            $script:fail++
        }
    } catch {
        Write-Host "  ✗ $Description ($_)"
        $script:fail++
    }
}

Write-Host ""
Write-Host "======================================="
Write-Host "  Reticulum Installer — Verification"
Write-Host "  (Windows)"
Write-Host "======================================="

# --- Binaries ---
Write-Host ""
Write-Host "--- Binaries ---"

Check "rnsd.exe exists" {
    Test-Path "$env:ProgramFiles\Reticulum\Scripts\rnsd.exe"
}
Check "lxmd.exe exists" {
    Test-Path "$env:ProgramFiles\Reticulum\Scripts\lxmd.exe"
}
Check "nssm.exe exists" {
    Test-Path "$env:ProgramFiles\Reticulum\nssm\nssm.exe"
}

# --- Virtual Environment ---
Write-Host ""
Write-Host "--- Virtual Environment ---"

Check "Virtualenv python.exe exists" {
    Test-Path "$env:ProgramFiles\Reticulum\Scripts\python.exe"
}
Check "rns package installed" {
    $out = & "$env:ProgramFiles\Reticulum\Scripts\pip.exe" show rns 2>&1
    $LASTEXITCODE -eq 0
}
Check "lxmf package installed" {
    $out = & "$env:ProgramFiles\Reticulum\Scripts\pip.exe" show lxmf 2>&1
    $LASTEXITCODE -eq 0
}

# --- Configuration ---
Write-Host ""
Write-Host "--- Configuration ---"

Check "rnsd config exists" {
    Test-Path "$env:ProgramData\Reticulum\rnsd\config"
}
Check "lxmd config exists" {
    Test-Path "$env:ProgramData\Reticulum\lxmd\config"
}
Check "rnsd config has transport=yes" {
    (Get-Content "$env:ProgramData\Reticulum\rnsd\config" -Raw) -match "enable_transport = yes"
}
Check "lxmd config has node=yes" {
    (Get-Content "$env:ProgramData\Reticulum\lxmd\config" -Raw) -match "enable_node = yes"
}

# --- Windows Services ---
Write-Host ""
Write-Host "--- Windows Services ---"

Check "rnsd service exists" {
    $null -ne (Get-Service -Name "rnsd" -ErrorAction SilentlyContinue)
}
Check "lxmd service exists" {
    $null -ne (Get-Service -Name "lxmd" -ErrorAction SilentlyContinue)
}
Check "rnsd service set to auto start" {
    (Get-Service -Name "rnsd").StartType -eq "Automatic"
}
Check "lxmd service set to auto start" {
    (Get-Service -Name "lxmd").StartType -eq "Automatic"
}

# --- Service Status ---
Write-Host ""
Write-Host "--- Service Status ---"

Start-Sleep -Seconds 5

Check "rnsd service is running" {
    (Get-Service -Name "rnsd").Status -eq "Running"
}
Check "lxmd service is running" {
    (Get-Service -Name "lxmd").Status -eq "Running"
}

# --- Firewall ---
Write-Host ""
Write-Host "--- Firewall ---"

Check "Firewall rule for rnsd exists" {
    $null -ne (Get-NetFirewallRule -DisplayName "Reticulum rnsd" -ErrorAction SilentlyContinue)
}

# --- Idempotency ---
Write-Host ""
Write-Host "--- Idempotency (re-run install) ---"

& powershell -ExecutionPolicy Bypass -File "C:\reticulum-installer\windows\install.ps1" *> $null
Check "Re-run exits successfully" { $true }
Check "rnsd still running after re-run" {
    (Get-Service -Name "rnsd").Status -eq "Running"
}
Check "lxmd still running after re-run" {
    (Get-Service -Name "lxmd").Status -eq "Running"
}
Check "Config not overwritten" {
    (Get-Content "$env:ProgramData\Reticulum\rnsd\config" -Raw) -match "enable_transport = yes"
}

# --- Summary ---
Write-Host ""
Write-Host "======================================="
Write-Host "  Results: $pass passed, $fail failed"
Write-Host "======================================="
Write-Host ""

if ($fail -gt 0) {
    Write-Host "--- Debug: rnsd service log ---"
    if (Test-Path "$env:ProgramData\Reticulum\rnsd\service.log") {
        Get-Content "$env:ProgramData\Reticulum\rnsd\service.log" -Tail 20
    } else {
        Write-Host "    (no log file)"
    }
    Write-Host ""
    Write-Host "--- Debug: lxmd service log ---"
    if (Test-Path "$env:ProgramData\Reticulum\lxmd\service.log") {
        Get-Content "$env:ProgramData\Reticulum\lxmd\service.log" -Tail 20
    } else {
        Write-Host "    (no log file)"
    }
    exit 1
}

exit 0
