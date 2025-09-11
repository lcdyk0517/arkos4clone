@echo off
setlocal enabledelayedexpansion

REM ========= User Config =========
set "SCRIPT=boot_dtb_tool.py"
set "EXE_BASENAME=dtb_selector"
REM Optional: .ico icon (leave empty to skip)
set "ICON="
REM Optional: UPX directory to compress (leave empty to skip)
set "UPX_DIR="
REM =================================

echo.
echo [1/5] Checking PyInstaller...
where pyinstaller >nul 2>nul
if errorlevel 1 (
  echo PyInstaller not found. Installing...
  py -m pip install --upgrade pyinstaller || (
    echo Failed to install PyInstaller.
    exit /b 1
  )
)

echo.
echo [2/5] Cleaning old artifacts...
if exist build rd /s /q build
if exist dist rd /s /q dist
if exist __pycache__ rd /s /q __pycache__
for %%F in (*.spec) do del /q "%%F"

echo.
echo [3/5] Building EXE...
set "ICON_FLAG="
if defined ICON set "ICON_FLAG=--icon=%ICON%"

set "UPX_FLAG="
if defined UPX_DIR set "UPX_FLAG=--upx-dir=%UPX_DIR%"

pyinstaller --noconfirm --onefile --console --name "%EXE_BASENAME%" %ICON_FLAG% %UPX_FLAG% "%SCRIPT%"
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

echo.
echo [4/5] Moving EXE to current directory...
if not exist "dist\%EXE_BASENAME%.exe" (
  echo EXE not found in dist. Something went wrong.
  exit /b 1
)

REM Overwrite existing exe if present
if exist "%EXE_BASENAME%.exe" del /q "%EXE_BASENAME%.exe"
move /Y "dist\%EXE_BASENAME%.exe" "%CD%\%EXE_BASENAME%.exe" >nul

echo.
echo [5/5] Cleaning intermediate files...
if exist build rd /s /q build
if exist dist rd /s /q dist
if exist __pycache__ rd /s /q __pycache__
if exist "%EXE_BASENAME%.spec" del /q "%EXE_BASENAME%.spec"

echo.
echo ✅ Done. The EXE is in:
echo     %CD%\%EXE_BASENAME%.exe
endlocal
