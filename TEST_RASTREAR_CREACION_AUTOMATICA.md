# 🔍 TEST: RASTREAR CREACIÓN AUTOMÁTICA DE SALAS

## 📋 Logging Agregado

### ✅ 1. En `createGameRoom()`:
```
🏗️ ========== CREATEROOM LLAMADO ==========
🏗️ Host: [NOMBRE]
🏗️ Público: [true/false]
🏗️ Timestamp: [FECHA]
🏗️ Stack trace: [MUESTRA DÓNDE SE LLAMÓ]
🏗️ =====================================
```

### ✅ 2. En `_startHeartbeat()`:
```
💓 Iniciando heartbeat para sala [CODIGO], jugador [ID]
💓 Ejecutando heartbeat para sala [CODIGO]
🔍 Ejecutando checkPlayerAbandonment para sala [CODIGO]
```

### ✅ 3. En `_stopHeartbeat()`:
```
🛑 Deteniendo heartbeat y todos los timers
🛑 RoomId actual: [CODIGO]
🛑 PlayerId actual: [ID]
✅ Todos los timers cancelados
```

### ✅ 4. En `cleanupCompletely()`:
```
🧹 ========== CLEANUP COMPLETO ==========
🧹 Estado antes: RoomId=[CODIGO], PlayerId=[ID]
🧹 Estado después: RoomId=null, PlayerId=null
🧹 ===================================
```

## 🧪 PASOS PARA IDENTIFICAR EL PROBLEMA:

### 1. **Ejecutar la app con logs:**
```bash
flutter run --debug
```

### 2. **Eliminar todas las salas de Firebase**
- Ir a Firebase Console
- Eliminar todo el nodo `gameRooms`

### 3. **Observar logs sin tocar nada:**
- Si ves `🏗️ CREATEROOM LLAMADO` SIN haber presionado "Crear Sala"
- El `Stack trace` te mostrará EXACTAMENTE dónde se está ejecutando

### 4. **Buscar estos patterns sospechosos:**
```
💓 Ejecutando heartbeat para sala [CODIGO]
// ^ Si aparece SIN haber unido a sala = PROBLEMA

🔍 Ejecutando checkPlayerAbandonment para sala [CODIGO]  
// ^ Si aparece con sala que no existe = PROBLEMA
```

## 🚨 POSIBLES CAUSAS:

### **Causa 1: Timer huérfano**
- Un timer de heartbeat sigue ejecutándose
- Buscar: `💓 Ejecutando heartbeat` sin haber creado sala

### **Causa 2: Listener zombie**
- Un listener sigue activo después de salir de sala
- Buscar: Múltiples `🔄 Listener - Sala actualizada`

### **Causa 3: Auto-reconnect**
- Código que detecta desconexión e intenta reconectar
- Buscar: `🏗️ CREATEROOM LLAMADO` en el stack trace

### **Causa 4: Estados inconsistentes**
- Variables `_currentRoomId` no se limpian correctamente
- Buscar: Estados donde RoomId != null pero sala no existe

## 🛠️ COMANDOS DE EMERGENCIA:

### **Limpiar manualmente desde código:**
```dart
FirebaseService.globalCleanup(); // ← Usar esto si es necesario
```

### **Forzar cleanup al salir de cualquier pantalla:**
```dart
@override
void dispose() {
  FirebaseService.globalCleanup();
  super.dispose();
}
```

## 🎯 RESULTADO ESPERADO:

**Normal** (sin problema):
```
✅ App iniciada
👤 Usuario navega por menús
🏗️ CREATEROOM LLAMADO ← Solo cuando presiona "Crear Sala"
💓 Iniciando heartbeat ← Solo después de crear sala
```

**Problemático** (con bug):
```
✅ App iniciada
🏗️ CREATEROOM LLAMADO ← ¡SIN haber presionado nada!
Stack trace: [Aquí verás el origen del problema]
```

## 📝 SIGUIENTE PASO:

1. **Ejecuta la app**
2. **Elimina salas de Firebase**  
3. **Copia y pega TODOS los logs**
4. **Identifica el `Stack trace` problemático**

¡Con esto podremos encontrar exactamente dónde está la creación automática! 🕵️