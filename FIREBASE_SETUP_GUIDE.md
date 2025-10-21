# Guía de Configuración de Firebase

## Estado Actual
✅ **Sistema de autenticación híbrido implementado**
- AuthService completamente funcional
- Soporte para usuarios locales y en la nube
- Login con Facebook y Google configurado
- Migración automática de datos locales

## Próximos Pasos

### 1. Crear Proyecto Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Clic en "Crear proyecto"
3. Nombre: `parchis-reverse-app`
4. Habilitar Google Analytics (opcional)

### 2. Configurar Authentication

1. En Firebase Console, ve a "Authentication"
2. Pestaña "Sign-in method"
3. Habilitar:
   - **Facebook**: Necesitarás App ID y App Secret de Facebook Developers
   - **Google**: Se configura automáticamente
   - **Anónimo**: Para usuarios invitados

### 3. Configurar Firestore

1. Ve a "Firestore Database"
2. Crear base de datos en modo "test" (por ahora)
3. Reglas iniciales:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura/escritura a usuarios autenticados
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Estadísticas de juego
    match /gameStats/{statId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 4. Configurar Android

1. En Firebase Console, agregar app Android
2. Package name: `com.example.parchis_reverse_app`
3. Descargar `google-services.json`
4. Colocar en: `android/app/google-services.json`

### 5. Configurar iOS

1. En Firebase Console, agregar app iOS
2. Bundle ID: `com.example.parchisReverseApp`
3. Descargar `GoogleService-Info.plist`
4. Colocar en: `ios/Runner/GoogleService-Info.plist`

### 6. Configurar Facebook Login

✅ **YA CONFIGURADO** - Tu App ID: `2352086431974551`

1. ✅ App creada en [Facebook Developers](https://developers.facebook.com/)
2. ✅ Tipo "Personal" para evitar problemas de portafolio
3. ✅ "Facebook Login" agregado
4. ✅ Android configurado:
   - **Package Name**: `com.example.parchis_reverse_app`
   - **Default Activity Class**: `com.example.parchis_reverse_app.MainActivity`
   - **Key Hash**: `ZOj8Rx2bu24OQRnrivxA4pgKMik=`
5. ✅ iOS configurado:
   - **Bundle ID**: `com.example.parchisReverseApp`
6. ✅ **App ID**: `2352086431974551` y **App Secret**: `84e538ea496b624f080e0e71039a5a84`

#### Archivos ya actualizados:
- ✅ `android/app/src/main/res/values/strings.xml`
- ✅ `android/app/src/main/AndroidManifest.xml`
- ✅ `ios/Runner/Info.plist`

#### Generar Key Hash (si necesitas regenerarlo):
```powershell
# 1. Obtener SHA-1 fingerprint
keytool -list -v -keystore "C:\Users\[TU_USUARIO]\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# 2. Convertir a Base64
$sha1 = "TU_SHA1_AQUÍ"; $bytes = ($sha1 -split ':' | ForEach-Object { [byte]('0x' + $_) }); [System.Convert]::ToBase64String($bytes)
```

### 7. Configuración Web (Opcional)

1. En Firebase Console, agregar app Web
2. Copiar configuración
3. Actualizar `web/index.html`

## Archivos Críticos

### android/app/build.gradle
Verificar que tenga:
```gradle
dependencies {
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.facebook.android:facebook-android-sdk:latest.release'
}
```

### ios/Runner/Info.plist
Verificar esquemas URL para Facebook:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>facebook-login</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fb[APP-ID]</string>
        </array>
    </dict>
</array>
```

## Testing

Una vez configurado Firebase:

1. **Login Facebook**: Probar en dispositivo físico (no emulador)
2. **Login Google**: Funciona en emulador y dispositivo
3. **Datos locales**: Verificar migración automática
4. **Modo offline**: Confirmar funcionalidad sin internet

## Estructura de Datos en Firestore

```
users/{userId}
├── nickname: String
├── isGuest: Boolean
├── email: String (opcional)
├── photoURL: String (opcional)
├── createdAt: Timestamp
├── lastLoginAt: Timestamp
└── gameStats: Map
    ├── totalGames: Number
    ├── totalWins: Number
    ├── winStreak: Number
    └── lastGameAt: Timestamp
```

## Troubleshooting

### Error: "No matching client found"
- Verificar que `google-services.json` esté en `android/app/`
- Confirmar package name en Firebase y `android/app/build.gradle`

### Facebook Login no funciona
- Verificar key hash en Facebook Developers
- Confirmar App ID en Firebase Authentication

### Firestore: Permission denied
- Revisar reglas de seguridad
- Confirmar que el usuario esté autenticado

---

**Nota**: El sistema ya está preparado para funcionar sin Firebase. Los usuarios pueden usar la app como invitados hasta que Firebase esté configurado.