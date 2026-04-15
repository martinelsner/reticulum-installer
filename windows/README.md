# Windows Installation

Automated deployment for Windows. This environment leverages `winget` for system dependencies and [NSSM](https://nssm.cc/) for reliable background service management.

## Quick Install

To install `rnsd` and `lxmd`, open an **Administrator PowerShell** and run:

```powershell
Invoke-WebRequest -Uri "https://codeberg.org/melsner/reticulum-installer/archive/main.zip" -OutFile "$env:TEMP\reticulum.zip"
Expand-Archive "$env:TEMP\reticulum.zip" -DestinationPath "$env:TEMP\reticulum" -Force
Set-Location "$env:TEMP\reticulum\reticulum-installer\windows"
powershell -ExecutionPolicy Bypass -File install.ps1
```

## What This Does

Running the installer script will:

1. Install Python via `winget` if not already present.
2. Build a virtual environment at `C:\Program Files\Reticulum` and install `rns` and `lxmf`.
3. Download and install [NSSM](https://nssm.cc/) for service management.
4. Establish `C:\ProgramData\Reticulum` as the data directory and copy across default configurations.
5. Register, configure, and start Windows Services: `rnsd` and `lxmd`.
6. Add a firewall rule for inbound TCP on port 4242.

## Data Files

Service data is stored at `C:\ProgramData\Reticulum\` with per-service subdirectories:
- **`rnsd`**: `C:\ProgramData\Reticulum\rnsd\`
- **`lxmd`**: `C:\ProgramData\Reticulum\lxmd\`

## Managing the Service

**Service Status (PowerShell):**
```powershell
Get-Service rnsd, lxmd
```

**Viewing Logs:**
```powershell
Get-Content "$env:ProgramData\Reticulum\rnsd\service.log" -Tail 50 -Wait
Get-Content "$env:ProgramData\Reticulum\lxmd\service.log" -Tail 50 -Wait
```

**Restarting After Config Changes:**
```powershell
Restart-Service rnsd, lxmd
```

## Uninstallation

If you wish to cleanly remove the services and virtual environment while leaving your data intact, open an **Administrator PowerShell** and run:

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

To purge the deployment entirely (including identities, messages and databases), also run:
```powershell
Remove-Item -Recurse -Force "$env:ProgramData\Reticulum"
```
