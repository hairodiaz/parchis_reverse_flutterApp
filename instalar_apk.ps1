# PARCHIS REVERSE APP - INSTALADOR POWERSHELL
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   PARCHIS REVERSE APP - INSTALADOR" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si ADB está disponible
try {
    $adbVersion = adb version 2>$null
    Write-Host "✅ ADB encontrado" -ForegroundColor Green
} catch {
    Write-Host "❌ ADB no encontrado. Instalación manual requerida." -ForegroundColor Red
    Write-Host ""
    Write-Host "📋 PASOS MANUALES:" -ForegroundColor Yellow
    Write-Host "1. Copia app-release.apk a tu móvil"
    Write-Host "2. Habilita 'Fuentes desconocidas' en tu móvil"
    Write-Host "3. Abre el APK desde el explorador de archivos"
    Write-Host "4. Presiona 'Instalar'"
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
    exit 1
}

# Verificar si el APK existe
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "❌ APK no encontrado en: $apkPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Ejecuta primero: flutter build apk --release" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
    exit 1
}

Write-Host "✅ APK encontrado" -ForegroundColor Green
Write-Host ""

# Verificar dispositivos conectados
Write-Host "📱 Buscando dispositivos conectados..." -ForegroundColor Blue
adb devices

Write-Host ""
Write-Host "🚀 Instalando APK en el dispositivo..." -ForegroundColor Blue

try {
    adb install -r $apkPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ ¡APK instalado correctamente!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎮 PRUEBA EL MULTIJUGADOR:" -ForegroundColor Cyan
        Write-Host "1. Abre la app en tu móvil"
        Write-Host "2. Inicia sesión"  
        Write-Host "3. Presiona 'JUGAR ONLINE'"
        Write-Host "4. Crea una sala y comparte el código"
        Write-Host ""
    } else {
        throw "Error en la instalación"
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error en la instalación" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 POSIBLES SOLUCIONES:" -ForegroundColor Yellow
    Write-Host "- Habilita 'Depuración USB' en tu móvil"
    Write-Host "- Acepta la instalación desde fuentes desconocidas"
    Write-Host "- Verifica que el cable USB esté conectado"
    Write-Host ""
}

Read-Host "Presiona Enter para cerrar"