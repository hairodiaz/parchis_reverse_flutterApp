@echo off
echo ========================================
echo   PARCHIS REVERSE APP - INSTALADOR
echo ========================================
echo.

REM Verificar si ADB está disponible
adb version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ ADB no encontrado. Instalación manual requerida.
    echo.
    echo 📋 PASOS MANUALES:
    echo 1. Copia app-release.apk a tu móvil
    echo 2. Habilita "Fuentes desconocidas" en tu móvil
    echo 3. Abre el APK desde el explorador de archivos
    echo 4. Presiona "Instalar"
    echo.
    pause
    exit /b 1
)

echo ✅ ADB encontrado
echo.

REM Verificar si el APK existe
if not exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ❌ APK no encontrado en: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo 🔧 Ejecuta primero: flutter build apk --release
    echo.
    pause
    exit /b 1
)

echo ✅ APK encontrado
echo.

REM Verificar dispositivos conectados
echo 📱 Buscando dispositivos conectados...
adb devices

echo.
echo 🚀 Instalando APK en el dispositivo...
adb install -r build\app\outputs\flutter-apk\app-release.apk

if %errorlevel% equ 0 (
    echo.
    echo ✅ ¡APK instalado correctamente!
    echo.
    echo 🎮 PRUEBA EL MULTIJUGADOR:
    echo 1. Abre la app en tu móvil
    echo 2. Inicia sesión
    echo 3. Presiona "JUGAR ONLINE"
    echo 4. Crea una sala y comparte el código
    echo.
) else (
    echo.
    echo ❌ Error en la instalación
    echo.
    echo 🔧 POSIBLES SOLUCIONES:
    echo - Habilita "Depuración USB" en tu móvil
    echo - Acepta la instalación desde fuentes desconocidas
    echo - Verifica que el cable USB esté conectado
    echo.
)

pause