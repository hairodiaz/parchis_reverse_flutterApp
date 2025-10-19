# 🧪 Plan de Pruebas - Sistema de Autenticación

## 📋 **Pruebas de Funcionalidad Básica**

### **Prueba 1: Verificar Inicialización**
**Objetivo**: Confirmar que Firebase y Hive se inicializan correctamente
**Pasos**:
1. Ejecutar `flutter run -d windows`
2. Verificar en logs:
   - ✅ "Base de datos local inicializada correctamente"
   - ✅ "Servicio de autenticación inicializado" 
   - ❌ NO debe aparecer errores de Firebase críticos

**Resultado Esperado**: App inicia sin crashes

---

### **Prueba 2: Usuario Invitado por Defecto**
**Objetivo**: Verificar que se crea usuario invitado automáticamente
**Pasos**:
1. Abrir app (primera vez)
2. Verificar en pantalla principal:
   - Nombre muestra "Invitado[Número]"
   - Estadísticas en 0
3. Ir a Settings → verificar "Usuario Invitado" en estado de cuenta

**Resultado Esperado**: Usuario invitado creado automáticamente

---

### **Prueba 3: Pantalla de Login**
**Objetivo**: Verificar que la UI de login funciona correctamente
**Pasos**:
1. Desde Settings → clic "Registrar Cuenta"
2. Verificar elementos de LoginScreen:
   - Logo y título "Parchis Reverse"
   - Sección de beneficios
   - Botón "Continuar con Facebook" (azul)
   - Botón "Continuar con Google" (blanco)
   - Opción "Continuar como invitado"

**Resultado Esperado**: UI completa y navegación fluida

---

## 🔐 **Pruebas de Autenticación**

### **Prueba 4: Login con Google (Emulador)**
**Objetivo**: Probar flujo completo de Google Sign-In
**Pasos**:
1. En LoginScreen → clic "Continuar con Google"
2. Seleccionar cuenta Google en el emulador
3. Verificar:
   - Loading screen aparece
   - Navegación a menu principal
   - Nombre cambia de "Invitado" a nombre real
   - Settings muestra "Cuenta Registrada"

**Resultado Esperado**: Login exitoso y migración de datos

---

### **Prueba 5: Logout y Conversión a Invitado**
**Objetivo**: Verificar que logout mantiene datos pero cambia estado
**Pasos**:
1. Estando logueado → ir a Settings
2. Clic "Cerrar Sesión" → confirmar
3. Verificar:
   - Estado cambia a "Usuario Invitado"
   - Estadísticas se mantienen
   - Botón "Registrar Cuenta" aparece

**Resultado Esperado**: Logout exitoso, datos preservados

---

### **Prueba 6: Re-login y Sincronización**
**Objetivo**: Verificar que re-login sincroniza datos correctamente
**Pasos**:
1. Después de logout → "Registrar Cuenta" → Google
2. Usar misma cuenta que antes
3. Verificar:
   - Datos sincronizados desde Firebase
   - Estadísticas correctas
   - Estado "Cuenta Registrada"

**Resultado Esperado**: Sincronización bidireccional funciona

---

## 📱 **Pruebas de Dispositivo Físico (Facebook)**

### **Prueba 7: Login con Facebook (Solo dispositivo físico)**
**Objetivo**: Probar Facebook Login en dispositivo real
**Requisitos**: Dispositivo Android/iOS físico
**Pasos**:
1. Conectar dispositivo físico
2. `flutter run` sin especificar dispositivo
3. En LoginScreen → "Continuar con Facebook"
4. Completar flow de Facebook
5. Verificar migración y sincronización

**Resultado Esperado**: Facebook login funcional

---

## 🔄 **Pruebas de Migración de Datos**

### **Prueba 8: Migración Usuario Invitado → Registrado**
**Objetivo**: Verificar que datos locales se migran a Firebase
**Configuración Previa**:
1. Jugar varias partidas como invitado
2. Cambiar nickname
3. Acumular estadísticas

**Pasos**:
1. Registrarse con Google/Facebook
2. Verificar en Firebase Console:
   - Usuario aparece en Authentication
   - Datos en Firestore collection 'users'
3. Verificar en app que stats se mantuvieron

**Resultado Esperado**: Migración completa sin pérdida de datos

---

## 🌐 **Pruebas de Conectividad**

### **Prueba 9: Funcionamiento Offline**
**Objetivo**: Verificar que app funciona sin internet
**Pasos**:
1. Deshabilitar WiFi/datos
2. Usar app como invitado:
   - Cambiar nickname
   - Jugar partidas
   - Verificar que datos se guardan localmente
3. Habilitar internet
4. Registrarse → verificar que datos offline se sincronizaron

**Resultado Esperado**: Funcionalidad completa offline

---

### **Prueba 10: Reconexión Automática**
**Objetivo**: Verificar sincronización al recuperar conexión
**Pasos**:
1. Estar logueado con internet
2. Perder conexión → seguir usando app
3. Recuperar conexión
4. Verificar que cambios se sincronizaron automáticamente

**Resultado Esperado**: Sincronización automática funciona

---

## 🐛 **Pruebas de Casos Edge**

### **Prueba 11: Cancelar Login**
**Objetivo**: Verificar manejo de cancelación de login
**Pasos**:
1. Iniciar login con Google/Facebook
2. Cancelar en pantalla de autorización
3. Verificar:
   - Regresa a LoginScreen
   - Mensaje apropiado
   - App no se bloquea

**Resultado Esperado**: Manejo elegante de cancelación

---

### **Prueba 12: Error de Red Durante Login**
**Objetivo**: Verificar manejo de errores de conectividad
**Pasos**:
1. Iniciar login
2. Deshabilitar internet durante el proceso
3. Verificar mensaje de error apropiado
4. Reintentar con internet

**Resultado Esperado**: Errores manejados correctamente

---

## 📊 **Verificación en Firebase Console**

### **Prueba 13: Datos en Firebase Console**
**Objetivo**: Verificar que datos llegan correctamente a Firebase
**Pasos**:
1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Proyecto "parchis-reverse-app"
3. Verificar:
   - **Authentication**: Usuarios registrados aparecen
   - **Firestore**: Collection 'users' con datos correctos
   - **Realtime Database**: Estadísticas (si aplicable)

**Resultado Esperado**: Datos consistentes en Firebase

---

## ✅ **Checklist de Pruebas**

### **Funcionalidad Básica**
- [ ] App inicia sin errores
- [ ] Usuario invitado se crea automáticamente
- [ ] LoginScreen se muestra correctamente
- [ ] Navegación entre pantallas funciona

### **Autenticación**
- [ ] Google Sign-In funciona (emulador)
- [ ] Facebook Sign-In funciona (dispositivo físico)
- [ ] Logout funciona correctamente
- [ ] Re-login sincroniza datos

### **Migración de Datos**
- [ ] Datos de invitado se migran al registrarse
- [ ] Estadísticas se preservan
- [ ] Achievements se mantienen
- [ ] Nickname personalizado se conserva

### **Conectividad**
- [ ] App funciona offline
- [ ] Sincronización automática al reconectar
- [ ] Manejo de errores de red

### **Firebase Integration**
- [ ] Usuarios aparecen en Firebase Auth
- [ ] Datos se guardan en Firestore
- [ ] Estructura de datos es correcta

---

## 🎯 **Criterios de Éxito**

**✅ Sistema aprobado si:**
- Todas las pruebas básicas (1-3) pasan
- Al menos una de Google/Facebook login funciona
- Migración de datos preserva información
- App funciona offline sin crashes
- Datos aparecen correctamente en Firebase Console

**❌ Requiere corrección si:**
- App crashes al iniciar
- Login no funciona en ninguna plataforma
- Se pierden datos durante migración
- Errores críticos en logs