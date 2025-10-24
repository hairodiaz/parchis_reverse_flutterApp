# 🎵 Audio Assets - Parchis Reverse

## 📁 Estructura de Carpetas

### 🎶 `music/`
Música de fondo y temas principales:
- `background_music.mp3` - Música de fondo principal del juego
- `menu_music.mp3` - Música del menú principal
- `victory_theme.mp3` - Tema de victoria
- `defeat_theme.mp3` - Tema de derrota

### 🔊 `effects/`
Efectos de sonido del juego:
- `Dice.mp3` - Sonido de dado rodando
- `pop_ficha.mp3` - Sonido corto y preciso de mover ficha ✨
- `fichaMov.mp3` - Sonido largo de mover ficha (DEPRECADO)
- `Subir.mp3` - Sonido de subir ficha (captura/casa)
- `down_token.mp3` - Sonido de bajar ficha (ser capturado)
- `fanfare.mp3` - Sonido de victoria/fanfarria
- `risa.mp3` - Sonido de risa (CPU burlándose)
- `uiiiiiiii.mp3` - Sonido de emoción/sorpresa
- `pierde_turno.mp3` - Sonido de perder turno
- `lanzar_nuevo.mp3` - Sonido de nuevo lanzamiento/turno extra
- `timer.mp3` - Sonido de timer/tiempo límite

## 🎚️ Configuración de Audio

### Volúmenes Recomendados:
- **Música**: 0.0 - 1.0 (controlado por `musicVolume`)
- **Efectos**: 0.0 - 1.0 (controlado por `effectsVolume`)

### Formatos Soportados:
- `.mp3` - Recomendado para música
- `.wav` - Recomendado para efectos cortos
- `.ogg` - Alternativa multiplataforma

## 📱 Integración

Los archivos de audio serán cargados por el `AudioService` y controlados mediante:
- `GameSettings.musicVolume`
- `GameSettings.effectsVolume`
- `GameSettings.soundEnabled`

## 📝 Notas de Implementación

1. **Precarga**: Los efectos frecuentes se precargan al inicio
2. **Gestión de Memoria**: Los archivos grandes se cargan bajo demanda
3. **Configuración**: El usuario puede ajustar volúmenes independientemente
4. **Plataformas**: Optimizado para Android, iOS y Web

---
*Coloca aquí tus archivos de audio para el juego Parchis Reverse*