@echo off
REM IkwimPay - Quick Build Script for Play Store (Windows)
REM This script helps build the app for Google Play Store release

echo ======================================
echo IkwimPay - Play Store Build Script
echo ======================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo Flutter found
flutter --version | findstr /C:"Flutter"
echo.

REM Check if key.properties exists
if not exist "android\key.properties" (
    echo WARNING: android\key.properties not found!
    echo You need to create this file for signing the release build.
    echo See PLAYSTORE_BUILD_GUIDE.md for instructions.
    echo.
    set /p continue="Continue anyway? (y/n): "
    if /i not "%continue%"=="y" exit /b 1
)

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean
echo.

REM Get dependencies
echo Getting dependencies...
call flutter pub get
echo.

REM Ask what to build
echo What would you like to build?
echo 1) APK (for testing)
echo 2) App Bundle/AAB (for Play Store - RECOMMENDED)
echo 3) Both
set /p choice="Enter choice (1-3): "

if "%choice%"=="1" goto build_apk
if "%choice%"=="2" goto build_aab
if "%choice%"=="3" goto build_both
echo Invalid choice
pause
exit /b 1

:build_apk
echo.
echo Building APK...
call flutter build apk --release
echo.
echo APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-release.apk
goto end

:build_aab
echo.
echo Building App Bundle...
call flutter build appbundle --release
echo.
echo App Bundle built successfully!
echo Location: build\app\outputs\bundle\release\app-release.aab
goto end

:build_both
echo.
echo Building APK...
call flutter build apk --release
echo.
echo Building App Bundle...
call flutter build appbundle --release
echo.
echo Both builds completed successfully!
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo AAB Location: build\app\outputs\bundle\release\app-release.aab
goto end

:end
echo.
echo ======================================
echo Build Complete!
echo ======================================
echo.
echo Next steps:
echo 1. Test the release build on a physical device
echo 2. Upload to Google Play Console
echo 3. See PLAYSTORE_BUILD_GUIDE.md for detailed upload instructions
echo.
pause
