@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo       🛠️ FIN-GOAL BUILD TOOL UTILITY 🛠️
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

:: Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [❌ ERROR] Dự án yêu cầu cài đặt Node.js để chạy script build.
    echo Vui lòng tải Node.js tại https://nodejs.org/ và thử lại.
    pause
    exit /b 1
)

:: Check Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [❌ ERROR] Không tìm thấy Flutter CLI trong hệ thống.
    echo Vui lòng thêm Flutter vào PATH của bạn.
    pause
    exit /b 1
)

:MENU
echo Chọn nền tảng bạn muốn build:
echo   [1] Android APK (File cài đặt trực tiếp)
echo   [2] Android App Bundle - AAB (Để phát hành Google Play)
echo   [3] iOS IPA (Yêu cầu macOS để chạy)
echo   [4] Thoát
echo.

set /p platform_choice="Nhập lựa chọn của bạn [1-4]: "

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
echo [❌ Lựa chọn không hợp lệ! Vui lòng thử lại.]
echo.
goto MENU

:ENV_MENU
echo.
echo Chọn môi trường cấu hình:
echo   [1] Development (Sử dụng .env.development / lib/main_dev.dart)
echo   [2] Production (Sử dụng .env.production / lib/main.dart)
echo   [3] Quay lại menu trước
echo.

set /p env_choice="Nhập lựa chọn của bạn [1-3]: "

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
echo [❌ Lựa chọn không hợp lệ! Vui lòng thử lại.]
echo.
goto ENV_MENU

:RUN_BUILD
echo.
echo ⏳ Đang chạy lệnh build: node scripts\build_app.js %TARGET% %ENV%
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

node scripts\build_app.js %TARGET% %ENV%

if %errorlevel% neq 0 (
    echo.
    echo [❌ BUILD THẤT BẠI] Đã xảy ra lỗi trong quá trình build.
    echo.
    pause
    goto MENU
)

echo.
echo [🎉 HOÀN THÀNH] Quá trình build hoàn tất thành công!
echo.
pause
goto MENU

:END
echo Cảm ơn bạn đã sử dụng. Hẹn gặp lại!
endlocal
