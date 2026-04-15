#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Reticulum + LXMF Uninstaller for Windows

.DESCRIPTION
    Removes the Windows Services, virtualenv, and NSSM.
    Leaves configuration and user data intact.

.NOTES
    Usage: Run as Administrator
        powershell -ExecutionPolicy Bypass -File uninstall.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$VenvDir  = "$env:ProgramFiles\Reticulum"
$NssmExe  = "$VenvDir\nssm\nssm.exe"

Write-Host "==> Reticulum + LXMF Uninstaller (Windows)" -ForegroundColor Cyan
Write-Host ""

# ---------- Stop & Remove Services ----------

Write-Host "--- Stopping and removing services ---"

foreach ($svcName in @("lxmd", "rnsd")) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service $svcName -Force -ErrorAction SilentlyContinue
        if (Test-Path $NssmExe) {
            & $NssmExe remove $svcName confirm
        } else {
            sc.exe delete $svcName
        }
        Write-Host "    Removed $svcName service."
    } else {
        Write-Host "    $svcName service not found (skipped)."
    }
}

# ---------- Firewall Rules ----------

Write-Host ""
Write-Host "--- Removing firewall rules ---"

Remove-NetFirewallRule -DisplayName "Reticulum rnsd" -ErrorAction SilentlyContinue
Write-Host "    Removed firewall rule for rnsd."

# ---------- Virtualenv & NSSM ----------

Write-Host ""
Write-Host "--- Removing virtualenv and NSSM ---"

if (Test-Path $VenvDir) {
    Remove-Item $VenvDir -Recurse -Force
    Write-Host "    Removed $VenvDir"
} else {
    Write-Host "    $VenvDir not found (skipped)."
}

# ---------- Summary ----------

Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "  Uninstallation complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Note: The config/data directory ($env:ProgramData\Reticulum) was NOT removed."
Write-Host "If you wish to remove it completely, run:"
Write-Host "    Remove-Item -Recurse -Force '$env:ProgramData\Reticulum'"
Write-Host ""
