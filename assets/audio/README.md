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
- `dice_roll.mp3` - Sonido de dado rodando
- `piece_move.mp3` - Sonido de mover ficha
- `piece_capture.mp3` - Sonido de capturar ficha
- `piece_home.mp3` - Sonido de ficha llegando a casa
- `bounce_effect.mp3` - Sonido de efecto rebote
- `button_click.mp3` - Sonido de botón
- `notification.mp3` - Sonido de notificación
- `error.mp3` - Sonido de error
- `success.mp3` - Sonido de éxito

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