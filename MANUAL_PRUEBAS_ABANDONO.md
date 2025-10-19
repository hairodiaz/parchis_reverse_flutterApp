## 🧪 MANUAL DE PRUEBAS - ABANDONO SALA ESPERA

### 🎯 OBJETIVO
Verificar que las salas se cierren correctamente cuando alguien abandona la sala de espera.

### ⚡ PRUEBA RÁPIDA (Sin segundo dispositivo)

**Para probar solo con 1 dispositivo:**

1. **📱 Ejecutar la app:**
   ```
   flutter run --debug
   ```

2. **🏠 Crear sala:**
   - Ir a "Crear Sala Privada" o "Sala Pública"
   - Observar logs: `✅ Unido a sala: [CODIGO]`

3. **🚪 Simular abandono:**
   - Navegar hacia atrás (botón back)
   - O cerrar la app
   - Observar logs: `🏠 Host eliminó la sala` o `🗑️ Sala eliminada`

4. **🔄 Probar prevención duplicados:**
   - Crear sala
   - Ir al menú principal  
   - Volver a unirse a la misma sala
   - NO debería crear duplicado

### 📱 PRUEBA COMPLETA (Con 2 dispositivos/emuladores)

**Dispositivo A (Host):**
1. Crear sala privada
2. Compartir código con Dispositivo B
3. Esperar que B se una
4. CERRAR APP o navegar hacia atrás
5. **Resultado esperado:** Sala eliminada, B ve mensaje de sala cerrada

**Dispositivo B (Invitado):**
1. Unirse a sala de A usando código
2. Esperar en sala de espera
3. CERRAR APP o navegar hacia atrás  
4. **Resultado esperado:** A ve que B se fue, sala sigue activa

### 🔍 LOGS A BUSCAR

**Unión exitosa:**
```
✅ Unido a sala: ABC123
```

**Evitar duplicado:**
```
⚠️ Jugador Juan ya está en la sala como player_abc123
🔄 Jugador Juan reconectado a sala: ABC123
```

**Host abandona:**
```
🏠 Host eliminó la sala
🗑️ Sala ABC123 eliminada: Host left room
```

**Invitado abandona:**
```
👤 Jugador abandonó la sala
🔍 Verificando sala ABC123: 1/2 jugadores conectados
```

**Auto-cleanup:**
```
🚪 AUTO-CLEANUP: Si estoy en sala de espera, salir automáticamente
```

### ✅ CHECKLIST DE PRUEBAS

- [ ] Crear sala como host ✓
- [ ] Unirse como invitado ✓
- [ ] Host abandona → Sala eliminada ✓
- [ ] Invitado abandona → Solo se remueve invitado ✓
- [ ] Prevenir duplicados al unirse 2 veces ✓
- [ ] Auto-cleanup al cerrar app ✓
- [ ] Logs aparecen correctamente ✓

### 🚨 PROBLEMAS POSIBLES

Si algo no funciona:

1. **Verificar Firebase:** Asegúrate que esté configurado
2. **Verificar internet:** Los tests necesitan conexión
3. **Verificar logs:** Buscar errores en consola de Flutter
4. **Limpiar proyecto:** `flutter clean && flutter pub get`

### 🎯 SIGUIENTE PASO

Una vez que TODOS estos tests pasen → podemos continuar con los otros problemas de sincronización (movimientos, delays, etc.)