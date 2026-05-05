# 🧪 INSTRUCCIONES DE TESTING - MVP Online Simulado

## Flujo Completo a Probar

### 1️⃣ Pantalla Principal
- [ ] La app muestra el menú principal con 4 modos
- [ ] Botón "CLÁSICO" está disponible (verde)
- [ ] Botón "ONLINE" está disponible (verde) ← **NUEVO MVP**
- [ ] Botones "RANKED" y "TORNEO" muestran "Próximamente"

### 2️⃣ Botón ONLINE → OnlineMatchmakingScreen
**Pasos:**
1. Toca el botón "ONLINE" del carousel
2. Deberías ver:
   - [ ] Pantalla azul con título "🌐 JUGAR ONLINE"
   - [ ] Campo para ingresar tu apodo
   - [ ] Selector de 4 colores
   - [ ] Botón "🔍 BUSCAR JUGADORES"

**Valores de prueba:**
- Apodo: Tu nombre (ej: "Hairo")
- Color: Rojo (predeterminado)

### 3️⃣ Búsqueda de Jugadores (Simulada)
**Pasos:**
1. Ingresa tu apodo
2. Selecciona un color
3. Toca "🔍 BUSCAR JUGADORES"

**Lo que debería pasar:**
- [ ] Pantalla cambia a modo "Buscando..."
- [ ] Icono de radar pulsante (animación)
- [ ] Después de ~1 segundo: "¡1 jugador encontrado!"
- [ ] Después de ~2.5 segundos: "¡2 jugadores encontrados!"
- [ ] Después de ~4 segundos: "¡3 jugadores encontrados! ¡Iniciando partida! 🎮"
- [ ] Barra de progreso muestra 3/3 completa
- [ ] **⏳ Espera 1 segundo más**

### 4️⃣ Pantalla del Juego (CRÍTICO)
**Esto es lo que estábamos debuggeando:**

Después de la búsqueda, deberías ver:
- [ ] ✅ Tablero del Parchís con 4 fichas de colores
- [ ] ✅ Tu nombre en una de las esquinas
- [ ] ✅ Nombres "CPU 1", "CPU 2", "CPU 3" en las otras esquinas
- [ ] ✅ **Botón "Lanzar Dado" en el centro**
- [ ] ✅ Mensajes de turno ("Turno de [Tu Nombre]")

### 5️⃣ Interacción del Juego
**Prueba:**
1. Si es tu turno (debe decir tu nombre):
   - [ ] Toca el botón "Lanzar Dado"
   - [ ] El dado anima (gira 3 veces)
   - [ ] Sale un número (1-6)
   - [ ] Las fichas se mueven automáticamente
   
2. Si no es tu turno:
   - [ ] Espera a que termine la CPU
   - [ ] Los CPUs lanzan automáticamente
   - [ ] Se ven mensajes divertidos ("¡EYYY QUE SUERTE!", etc)

### 6️⃣ Comparar Modos
**Para asegurar que solo el modo online tiene el fix:**

**Modo Clásico (Local):**
1. Toca "CLÁSICO"
2. Configura 2-4 jugadores (mezcla humanos + CPU)
3. Inicia partida
- [ ] Debe funcionar normalmente

**Modo Online (Nuevo):**
1. Toca "ONLINE"
2. Busca jugadores
3. Inicia partida
- [ ] Ahora debería funcionar correctamente ✅

---

## 🐛 Bugs Conocidos a Reporte

Si encuentras algo que NO funciona:

### Bug Template
```
🐛 Título: [Descripción corta]
📱 Pantalla: [Menú Principal / OnlineMatchmaking / Tablero]
⏱️ Cuándo ocurre: [Paso a paso]
✅ Esperado: [Qué debería pasar]
❌ Real: [Qué pasó realmente]
📸 Screenshots: [Si es posible]
```

### Ejemplos de bugs a buscar:
- [ ] El botón "Lanzar Dado" no responde cuando es tu turno
- [ ] El dado no anima correctamente
- [ ] Las fichas no se mueven
- [ ] No se ven los CPUs
- [ ] Mensajes no aparecen
- [ ] La app se cierra/crashea
- [ ] Timer no funciona
- [ ] Colores incorrectos

---

## ✅ Criterios de Aceptación (MVP)

La versión MVP se considera **LISTA PARA PLAY STORE** si:

- [x] Menú principal muestra botón ONLINE disponible
- [ ] OnlineMatchmakingScreen se abre correctamente
- [ ] Búsqueda simulada funciona (5 segundos)
- [ ] Navega a ParchisBoard sin errores
- [ ] **CRÍTICO**: El botón Lanzar Dado es clicable
- [ ] Se puede jugar una partida completa contra CPUs
- [ ] Mensajes aparecen correctamente
- [ ] Audio funciona (dados, efectos)
- [ ] No hay crashes

---

## 📋 Checklist de Testing Completo

### Pre-Testing
- [ ] APK compilado exitosamente
- [ ] Dispositivo/Emulador listo
- [ ] Conexión a internet (no se usa, pero Flutter puede requerirlo)

### Testing
- [ ] Menú principal
- [ ] Transición ONLINE
- [ ] OnlineMatchmaking funciona
- [ ] Juego inicia
- [ ] Primer turno (CPU o usuario)
- [ ] Animación de dado
- [ ] Movimiento de fichas
- [ ] Casillas especiales
- [ ] Turnos alternados
- [ ] Victorias
- [ ] Salida y regreso al menú

### Post-Testing
- [ ] Documentar cualquier bug
- [ ] Rating general (1-5 ⭐)
- [ ] Recomendaciones

---

## 🎯 Objetivo Principal

**"¿Funciona el MVP online simulado sin crashes?"**

Si la respuesta es **SÍ**, entonces podemos proceder a:
1. ✅ Completar documentos legales (Tier 2)
2. ✅ Preparar Play Store (Tier 3)
3. ✅ Publicar MVP (2-3 semanas de trabajo completadas)

---

## 📊 Versión

**Versión a Testear**: 2.0 (MVP - Online Simulado)  
**Fecha**: Mayo 5, 2026  
**Tamaño APK**: ~64MB  
**Tiempo Esperado**: 15-30 minutos de testing  

---

**¡Buen testing! 🚀**

Si encuentras un bug crítico → reporta inmediatamente  
Si todo funciona → celebra y avancemos a Tier 2 📦
