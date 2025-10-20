@echo off
cls
echo ========================================
echo  PARCHIS REVERSE - DETECTOR DE MÓVIL
echo ========================================
echo.

echo 🔍 Buscando dispositivos conectados...
echo.

:check_devices
flutter devices

echo.
echo 📱 ¿Ves tu móvil en la lista?
echo.
echo [1] Sí, está mi móvil - Instalar APK
echo [2] No, voy a conectarlo - Verificar de nuevo  
echo [3] Generar APK para instalación manual
echo [4] Salir
echo.

set /p choice=Elige una opción (1-4): 

if "%choice%"=="1" goto install_mobile
if "%choice%"=="2" goto wait_and_check
if "%choice%"=="3" goto manual_apk
if "%choice%"=="4" goto end

goto check_devices

:install_mobile
echo.
echo 🚀 Instalando en móvil...
flutter run --release
goto end

:wait_and_check
echo.
echo ⏳ Conecta tu móvil con cable USB y habilita depuración USB
echo Presiona cualquier tecla cuando esté listo...
pause > nul
goto check_devices

:manual_apk
echo.
echo 📦 Generando APK para instalación manual...
echo.
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ✅ APK ya existe en: build\app\outputs\flutter-apk\app-release.apk
    echo 📱 Cópialo a tu móvil e instálalo manualmente
) else (
    echo ❌ APK no encontrado. Ejecutando build...
    flutter build apk --release --no-obfuscate --no-shrink
)
goto end

:end
echo.
echo ✅ ¡Listo!
pause