# 🚀 MIGRACIÓN A WEBSOCKET - GUÍA COMPLETA

## 📦 INSTALACIÓN DEL SERVIDOR

### 1. **Instalar Node.js** (si no lo tienes):
- Descargar de: https://nodejs.org/
- Versión recomendada: LTS (Long Term Support)

### 2. **Instalar dependencias del servidor:**
```bash
cd websocket_server
npm install
```

### 3. **Ejecutar el servidor:**
```bash
npm start
```

**Debería mostrar:**
```
🚀 Servidor WebSocket iniciado en puerto 8080
📡 Esperando conexiones...
```

## 📱 CONFIGURACIÓN EN FLUTTER

### 1. **Agregar dependencia WebSocket** (ya incluida en Flutter)
No necesitas agregar nada al `pubspec.yaml` - WebSocket es nativo.

### 2. **Importar el nuevo servicio:**
```dart
import 'websocket_service.dart';
```

### 3. **Reemplazar FirebaseService por WebSocketService:**
```dart
// ANTES ❌
final FirebaseService _firebaseService = FirebaseService();

// DESPUÉS ✅  
final WebSocketService _webSocketService = WebSocketService();
```

## 🔄 MIGRACIÓN PASO A PASO

### **Paso 1: Conectar al servidor**
```dart
// En initState()
await _webSocketService.connect();
```

### **Paso 2: Crear sala**
```dart
// Reemplazar FirebaseService.createGameRoom()
final roomCode = await _webSocketService.createRoom(playerName);
```

### **Paso 3: Unirse a sala**
```dart
// Reemplazar FirebaseService.joinGameRoom()
final success = await _webSocketService.joinRoom(roomCode, playerName);
```

### **Paso 4: Escuchar eventos**
```dart
// Reemplazar Firebase listeners
_webSocketService.messageStream.listen((message) {
  switch (message['type']) {
    case 'player_joined':
      // Actualizar UI con nuevo jugador
      break;
    case 'player_left':
      // Actualizar UI sin jugador
      break;
    case 'dice_rolled':
      // Actualizar dado
      break;
    case 'game_move':
      // Actualizar posiciones
      break;
  }
});
```

### **Paso 5: Enviar movimientos**
```dart
// Reemplazar Firebase updates
_webSocketService.sendDiceRoll(diceValue, currentPlayer);
_webSocketService.sendGameMove(pieces, currentPlayer);
```

## ✅ VENTAJAS INMEDIATAS

### **🚀 Performance:**
- **Firebase:** 500-2000ms de latencia
- **WebSocket:** 10-50ms de latencia

### **🧹 Cleanup automático:**
- **Firebase:** Salas zombies que no se eliminan
- **WebSocket:** Se desconecta = sale de sala automáticamente

### **🎮 Control total:**
- **Firebase:** Problemas de sincronización complejos
- **WebSocket:** Estado controlado 100% por nosotros

### **💰 Costo:**
- **Firebase:** Lectura/escrituras cobradas
- **WebSocket:** Servidor local gratuito

## 🧪 PRIMERA PRUEBA

### 1. **Ejecutar servidor:**
```bash
cd websocket_server
npm start
```

### 2. **Conectar desde Flutter:**
```dart
final success = await WebSocketService().connect();
if (success) {
  print('✅ Conectado al servidor');
}
```

### 3. **Crear sala de prueba:**
```dart
final roomCode = await WebSocketService().createRoom('TestPlayer');
print('🏠 Sala creada: $roomCode');
```

## 🔄 PRÓXIMOS PASOS

1. ✅ **Servidor WebSocket creado**
2. ✅ **WebSocketService para Flutter creado**
3. 🔄 **Reemplazar FirebaseService en main.dart**
4. 🔄 **Migrar pantallas de sala de espera**
5. 🔄 **Migrar sincronización de juego**
6. 🔄 **Probar funcionamiento completo**

¿Quieres que empecemos a reemplazar FirebaseService en el código de Flutter? 🚀