@echo off
REM Post-install script executed by dockur/windows after Windows setup.
REM This runs the Reticulum installer, then the verification suite.
REM Results are echoed to stdout (captured in container logs).

echo ===========================================================
echo   RETICULUM_TEST: Starting installer
echo ===========================================================

REM Copy the installer tree to a local path
mkdir C:\reticulum-installer 2>nul
xcopy /E /Y /Q C:\OEM\installer C:\reticulum-installer\

REM Run the installer
powershell -ExecutionPolicy Bypass -File C:\reticulum-installer\windows\install.ps1
set INSTALL_EXIT=%ERRORLEVEL%

if %INSTALL_EXIT% EQU 0 (
    echo ===========================================================
    echo   RETICULUM_TEST: INSTALL_OK
    echo ===========================================================
) else (
    echo ===========================================================
    echo   RETICULUM_TEST: INSTALL_FAILED exit_code=%INSTALL_EXIT%
    echo ===========================================================
    exit /b %INSTALL_EXIT%
)

REM Wait for services to settle
timeout /t 15 /nobreak >nul

REM Run the verification suite
echo ===========================================================
echo   RETICULUM_TEST: Starting verification
echo ===========================================================

powershell -ExecutionPolicy Bypass -File C:\OEM\verify.ps1
set VERIFY_EXIT=%ERRORLEVEL%

if %VERIFY_EXIT% EQU 0 (
    echo ===========================================================
    echo   RETICULUM_TEST: VERIFY_OK
    echo ===========================================================
) else (
    echo ===========================================================
    echo   RETICULUM_TEST: VERIFY_FAILED exit_code=%VERIFY_EXIT%
    echo ===========================================================
)

exit /b %VERIFY_EXIT%
