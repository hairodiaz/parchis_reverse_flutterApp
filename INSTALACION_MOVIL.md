# 📱 INSTALACIÓN EN MÓVIL - PARCHÍS REVERSE APP

## 🎯 **ARCHIVO APK GENERADO:**
Una vez que termine la compilación, encontrarás el APK en:
```
build/app/outputs/flutter-apk/app-release.apk
```

## 📲 **PASOS PARA INSTALAR EN TU MÓVIL:**

### **1. Preparar tu Móvil Android:**
- ✅ Ve a **Configuración > Seguridad**
- ✅ Habilita **"Fuentes desconocidas"** o **"Instalar aplicaciones desconocidas"**
- ✅ En algunos móviles: **Configuración > Biometría y seguridad > Instalar aplicaciones desconocidas**

### **2. Transferir el APK:**
**Opción A - Cable USB:**
```bash
# Copiar APK al móvil
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Opción B - Transferencia Manual:**
- Copia `app-release.apk` a tu móvil (USB, Google Drive, WhatsApp, etc.)
- Abre el archivo desde el explorador de archivos
- Presiona "Instalar"

### **3. Verificar Instalación:**
- ✅ Busca el ícono "parchis_reverse_app" en tu móvil
- ✅ Ábrela y verifica que funcione

## 🎮 **PROBAR MULTIJUGADOR ONLINE:**

### **Opción 1: Móvil + Emulador**
1. **En tu móvil:**
   - Abrir app → Login → "JUGAR ONLINE" → "CREAR SALA"
   - **Anotar el código (ej: ABC123)**

2. **En el emulador (PC):**
   ```bash
   flutter run -d emulator-5554
   ```
   - Abrir app → Login → "JUGAR ONLINE" → "UNIRSE A SALA"
   - Introducir el código del móvil
   - **¡Deberías ver ambos jugadores sincronizados!**

### **Opción 2: Dos Móviles**
1. Instala el APK en dos móviles diferentes
2. Repite el proceso: uno crea sala, otro se une
3. ¡Disfruta del multijugador!

## 🔧 **INFORMACIÓN TÉCNICA:**

### **Características del APK:**
- ✅ **Optimizado**: Minificación y compresión habilitadas
- ✅ **Firebase**: Completamente configurado
- ✅ **Tamaño**: Optimizado para distribución
- ✅ **Compatibilidad**: Android 5.0+ (API 21+)

### **Funcionalidades Incluidas:**
- ✅ Sistema de login con 4 usuarios
- ✅ Juego completo de Parchís Dominicano
- ✅ Multijugador online con Firebase
- ✅ Salas en tiempo real
- ✅ Sincronización de jugadores
- ✅ UI/UX optimizada

## 🌐 **CONEXIÓN A INTERNET:**
**IMPORTANTE**: Para el multijugador online, ambos dispositivos necesitan:
- ✅ Conexión a Internet (WiFi o datos móviles)
- ✅ Acceso a Firebase (sin restricciones de firewall)

## 🚨 **SOLUCIÓN DE PROBLEMAS:**

### **Si no puedes instalar:**
1. Verifica que "Fuentes desconocidas" esté habilitado
2. Asegúrate de tener espacio suficiente (aprox. 50MB)
3. Verifica que tu Android sea 5.0 o superior

### **Si el multijugador no funciona:**
1. Verifica conexión a Internet
2. Asegúrate de que Firebase esté funcionando (crea una sala para verificar)
3. Reinicia la app si es necesario

### **Logs de Depuración:**
Si tienes problemas, conecta el móvil por USB y ejecuta:
```bash
adb logcat | grep flutter
```

## 🎉 **¡LISTO PARA JUGAR!**

Una vez instalado, tendrás:
- 🎮 Juego completo funcional
- 🌐 Multijugador online
- 👥 Sistema de usuarios
- 📱 Optimizado para móviles

**¡Disfruta tu juego de Parchís Dominicano con multijugador online!** 🚀