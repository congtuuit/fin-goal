@echo off
setlocal enabledelayedexpansion

echo ====================================================
echo       [*] FIN-GOAL BUILD TOOL UTILITY [*]
echo ====================================================
echo.

:: Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [X ERROR] Du an yeu cau cai dat Node.js de chay script build.
    echo Vui long tai Node.js tai https://nodejs.org/ va thu lai.
    pause
    exit /b 1
)

:: Check Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [X ERROR] Khong tim thay Flutter CLI trong he thong.
    echo Vui long them Flutter vao PATH cua ban.
    pause
    exit /b 1
)

:MENU
echo Chon nen tang ban muon build:
echo   [1] Android APK (File cai dat truc tiep)
echo   [2] Android App Bundle - AAB (De phat hanh Google Play)
echo   [3] iOS IPA (Yeu cau macOS de chay)
echo   [4] Thoat
echo.

set /p platform_choice="Nhap lua chon cua ban [1-4]: "

if "%platform_choice%"=="1" (
    set TARGET=apk
    goto ENV_MENU
)
if "%platform_choice%"=="2" (
    set TARGET=appbundle
    goto ENV_MENU
)
if "%platform_choice%"=="3" (
    set TARGET=ipa
    goto ENV_MENU
)
if "%platform_choice%"=="4" (
    goto END
)

echo.
echo [X Lua chon khong hop le! Vui long thu lai.]
echo.
goto MENU

:ENV_MENU
echo.
echo Chon moi truong cau hinh:
echo   [1] Development (Su dung .env.development / lib/main_dev.dart)
echo   [2] Production (Su dung .env.production / lib/main.dart)
echo   [3] Quay lai menu truoc
echo.

set /p env_choice="Nhap lua chon cua ban [1-3]: "

if "%env_choice%"=="1" (
    set ENV=dev
    goto RUN_BUILD
)
if "%env_choice%"=="2" (
    set ENV=prod
    goto RUN_BUILD
)
if "%env_choice%"=="3" (
    echo.
    goto MENU
)

echo.
echo [X Lua chon khong hop le! Vui long thu lai.]
echo.
goto ENV_MENU

:RUN_BUILD
echo.
echo [*] Dang chay lenh build: node scripts\build_app.js %TARGET% %ENV%
echo ====================================================
echo.

node scripts\build_app.js %TARGET% %ENV%

if %errorlevel% neq 0 (
    echo.
    echo [X BUILD THAT BAI] Da xay ra loi trong qua trinh build.
    echo.
    pause
    goto MENU
)

echo.
echo [v HOAN THANH] Qua trinh build hoan tat thanh cong!
echo.
pause
goto MENU

:END
echo Cam on ban da su dung. Hen gap lai!
endlocal
