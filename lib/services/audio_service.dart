import 'package:audioplayers/audioplayers.dart';
import '../services/hive_service.dart';
import '../models/game_settings.dart';

/// 🎵 SERVICIO DE AUDIO - Gestión de Sonidos y Música
/// 
/// Funcionalidades:
/// - 🎲 Efectos de sonido del juego
/// - 🎶 Música de fondo
/// - 🔊 Control de volumen independiente
/// - ⚙️ Configuración desde GameSettings
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // 🎵 Reproductores de audio
  final AudioPlayer _effectsPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  
  // 📊 Estado del servicio
  bool _isInitialized = false;
  bool _soundEnabled = true;
  double _effectsVolume = 0.8;
  double _musicVolume = 0.7;

  // 🚀 Inicializar servicio de audio
  Future<void> initialize() async {
    try {
      // Configurar reproductores
      await _effectsPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Cargar configuraciones
      _loadSettings();
      
      _isInitialized = true;
      print('🎵 AudioService inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando AudioService: $e');
    }
  }

  // ⚙️ Cargar configuraciones desde Hive
  void _loadSettings() {
    final settings = HiveService.getSettings();
    _effectsVolume = settings.effectsVolume;
    _musicVolume = settings.musicVolume;
    _soundEnabled = settings.soundEnabled;
    
    print('🔊 Configuración de audio cargada:');
    print('   Efectos: ${(_effectsVolume * 100).toInt()}%');
    print('   Música: ${(_musicVolume * 100).toInt()}%');
    print('   Habilitado: $_soundEnabled');
  }

  // 🎲 EFECTOS DE SONIDO DEL JUEGO

  /// Sonido del dado rodando
  Future<void> playDiceRoll() async {
    await _playEffect('Dice.mp3');
  }

  /// Sonido de mover ficha (pop corto y preciso)
  Future<void> playPieceMove() async {
    if (!_isInitialized || !_soundEnabled || _effectsVolume == 0.0) {
      return;
    }

    try {
      // 🎯 SONIDO CORTO Y PRECISO para movimiento de ficha (120ms)
      await _effectsPlayer.setVolume(_effectsVolume);
      await _effectsPlayer.play(AssetSource('audio/effects/pop_ficha_short.wav'));
      print('🔊 Reproduciendo efecto: pop_ficha_short.wav (120ms - perfecto para pasos)');
    } catch (e) {
      print('❌ Error reproduciendo pop_ficha.mp3: $e');
    }
  }

  /// Sonido de subir ficha (captura o llegada a casa)
  Future<void> playPieceUp() async {
    await _playEffect('Subir.mp3');
  }

  /// Sonido de bajar ficha (ser capturado)
  Future<void> playPieceDown() async {
    await _playEffect('down_token.mp3');
  }

  /// Sonido de victoria/fanfarria
  Future<void> playVictory() async {
    await _playEffect('fanfare.mp3');
  }

  /// Sonido de risa (CPU burlándose)
  Future<void> playLaugh() async {
    await _playEffect('risa.mp3');
  }

  /// Sonido de emoción/sorpresa
  Future<void> playExcitement() async {
    await _playEffect('uiiiiiiii.mp3');
  }

  /// Sonido de perder turno
  Future<void> playLoseTurn() async {
    await _playEffect('pierde_turno.mp3');
  }

  /// Sonido para nuevo lanzamiento/turno extra
  Future<void> playNewTurn() async {
    await _playEffect('lanzar_nuevo.mp3');
  }

  /// Sonido de timer/tiempo límite
  Future<void> playTimer() async {
    await _playEffect('timer.mp3');
  }

  // 🎵 Reproducir efecto de sonido
  Future<void> _playEffect(String filename) async {
    if (!_isInitialized || !_soundEnabled || _effectsVolume == 0.0) {
      return;
    }

    try {
      await _effectsPlayer.setVolume(_effectsVolume);
      await _effectsPlayer.play(AssetSource('audio/effects/$filename'));
      print('🔊 Reproduciendo efecto: $filename');
    } catch (e) {
      print('❌ Error reproduciendo $filename: $e');
    }
  }

  // 🎶 MÚSICA DE FONDO

  /// Reproducir música de fondo
  Future<void> playBackgroundMusic(String filename) async {
    if (!_isInitialized || !_soundEnabled || _musicVolume == 0.0) {
      return;
    }

    try {
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(AssetSource('audio/music/$filename'));
      print('🎶 Reproduciendo música: $filename');
    } catch (e) {
      print('❌ Error reproduciendo música $filename: $e');
    }
  }

  /// Pausar música de fondo
  Future<void> pauseBackgroundMusic() async {
    try {
      await _musicPlayer.pause();
      print('⏸️ Música pausada');
    } catch (e) {
      print('❌ Error pausando música: $e');
    }
  }

  /// Reanudar música de fondo
  Future<void> resumeBackgroundMusic() async {
    try {
      await _musicPlayer.resume();
      print('▶️ Música reanudada');
    } catch (e) {
      print('❌ Error reanudando música: $e');
    }
  }

  /// Detener música de fondo
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      print('⏹️ Música detenida');
    } catch (e) {
      print('❌ Error deteniendo música: $e');
    }
  }

  // ⚙️ CONFIGURACIÓN DE AUDIO

  /// Actualizar volumen de efectos
  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = volume.clamp(0.0, 1.0);
    await _effectsPlayer.setVolume(_effectsVolume);
    print('🔊 Volumen de efectos: ${(_effectsVolume * 100).toInt()}%');
  }

  /// Actualizar volumen de música
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
    print('🎶 Volumen de música: ${(_musicVolume * 100).toInt()}%');
  }

  /// Habilitar/deshabilitar sonido
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      stopBackgroundMusic();
    }
    print('🔊 Sonido ${enabled ? 'habilitado' : 'deshabilitado'}');
  }

  /// Actualizar configuraciones desde GameSettings
  void updateFromSettings(GameSettings settings) {
    _effectsVolume = settings.effectsVolume;
    _musicVolume = settings.musicVolume;
    _soundEnabled = settings.soundEnabled;
    
    // Aplicar cambios inmediatamente
    _effectsPlayer.setVolume(_effectsVolume);
    _musicPlayer.setVolume(_musicVolume);
    
    if (!_soundEnabled) {
      stopBackgroundMusic();
    }
  }

  // 🎮 EFECTOS ESPECIALES PARA EL JUEGO

  /// Secuencia de sonidos para victoria
  Future<void> playVictorySequence() async {
    await playVictory();
    await Future.delayed(const Duration(milliseconds: 500));
    await playExcitement();
  }

  /// Secuencia de sonidos para captura de ficha
  Future<void> playCaptureSequence() async {
    await playPieceDown();
    await Future.delayed(const Duration(milliseconds: 300));
    await playLaugh();
  }

  /// Efecto de sonido para rebote
  Future<void> playBounceEffect() async {
    await playExcitement(); // Usar sonido de sorpresa para el rebote
  }

  /// Efecto para llegada a META
  Future<void> playGoalEffect() async {
    await playPieceUp();
    await Future.delayed(const Duration(milliseconds: 200));
    await playExcitement();
  }

  // 📊 Getters
  bool get isInitialized => _isInitialized;
  bool get soundEnabled => _soundEnabled;
  double get effectsVolume => _effectsVolume;
  double get musicVolume => _musicVolume;

  // 🔇 DETENER TODOS LOS SONIDOS INMEDIATAMENTE
  Future<void> stopAllSounds() async {
    try {
      await _effectsPlayer.stop();
      await _musicPlayer.stop();
      print('🔇 Todos los sonidos detenidos');
    } catch (e) {
      print('⚠️ Error deteniendo sonidos: $e');
    }
  }

  // 🧹 Limpieza
  Future<void> dispose() async {
    await stopAllSounds(); // Detener sonidos antes de liberar recursos
    await _effectsPlayer.dispose();
    await _musicPlayer.dispose();
    print('🧹 AudioService liberado');
  }
}