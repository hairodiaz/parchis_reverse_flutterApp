import 'package:hive_flutter/hive_flutter.dart';
import '../models/local_user.dart';
import '../models/game_settings.dart';

/// 🗂️ HIVE SERVICE - Gestión de Base de Datos Local
/// 
/// Funciones principales:
/// - ✅ Inicializar Hive
/// - ✅ Gestionar usuarios locales
/// - ✅ Gestionar configuraciones
/// - ✅ Backup y sincronización
class HiveService {
  static const String _userBoxName = 'users';
  static const String _settingsBoxName = 'settings';
  static const String _statsBoxName = 'stats';

  // Cajas de Hive
  static Box<LocalUser>? _userBox;
  static Box<GameSettings>? _settingsBox;
  static Box? _statsBox;

  /// 🚀 Inicializar Hive
  static Future<void> init() async {
    try {
      // Inicializar Hive Flutter
      await Hive.initFlutter();

      // Registrar adaptadores
      Hive.registerAdapter(LocalUserAdapter());
      Hive.registerAdapter(GameSettingsAdapter());

      // Abrir cajas
      _userBox = await Hive.openBox<LocalUser>(_userBoxName);
      _settingsBox = await Hive.openBox<GameSettings>(_settingsBoxName);
      _statsBox = await Hive.openBox(_statsBoxName);

      print('✅ Hive inicializado correctamente');
      print('📊 Usuarios guardados: ${_userBox?.length ?? 0}');
      print('⚙️ Configuraciones guardadas: ${_settingsBox?.length ?? 0}');
    } catch (e) {
      print('❌ Error inicializando Hive: $e');
      rethrow;
    }
  }

  /// 👤 GESTIÓN DE USUARIOS

  /// Obtener usuario actual
  static LocalUser? getCurrentUser() {
    return _userBox?.get('current_user');
  }

  /// Guardar usuario actual
  static Future<void> saveCurrentUser(LocalUser user) async {
    await _userBox?.put('current_user', user);
    print('💾 Usuario guardado: ${user.name}');
  }

  /// Crear usuario invitado
  static Future<LocalUser> createGuestUser() async {
    final guestUser = LocalUser(
      name: 'Invitado',
      isGuest: true,
    );
    await saveCurrentUser(guestUser);
    return guestUser;
  }

  /// Crear usuario registrado
  static Future<LocalUser> createRegisteredUser({
    required String name,
    required String facebookId,
    String? email,
  }) async {
    final user = LocalUser(
      name: name,
      facebookId: facebookId,
      email: email,
      isGuest: false,
    );
    await saveCurrentUser(user);
    return user;
  }

  /// ⚙️ GESTIÓN DE CONFIGURACIONES

  /// Obtener configuraciones
  static GameSettings getSettings() {
    var settings = _settingsBox?.get('game_settings');
    if (settings == null) {
      // 🎯 Crear configuraciones por defecto si no existen
      settings = GameSettings();
      saveSettings(settings); // Guardar inmediatamente
      print('⚙️ Configuraciones por defecto creadas');
    }
    return settings;
  }

  /// Guardar configuraciones
  static Future<void> saveSettings(GameSettings settings) async {
    await _settingsBox?.put('game_settings', settings);
    print('⚙️ Configuraciones guardadas');
  }

  /// 📊 ESTADÍSTICAS GENERALES

  /// Guardar estadística general
  static Future<void> saveStat(String key, dynamic value) async {
    await _statsBox?.put(key, value);
  }

  /// Obtener estadística general
  static T? getStat<T>(String key) {
    return _statsBox?.get(key) as T?;
  }

  /// 📚 GESTIÓN DE PREFERENCIAS DE TUTORIAL

  /// Verificar si es la primera vez del usuario
  static bool isFirstTime() {
    return _statsBox?.get('is_first_time', defaultValue: true) ?? true;
  }

  /// Marcar que ya no es la primera vez
  static Future<void> setNotFirstTime() async {
    await _statsBox?.put('is_first_time', false);
    print('✅ Marcado como usuario experimentado');
  }

  /// Obtener configuración de mostrar tutorial
  static bool getShowTutorial() {
    return _statsBox?.get('show_tutorial', defaultValue: true) ?? true;
  }

  /// Establecer si mostrar tutorial
  static Future<void> setShowTutorial(bool show) async {
    await _statsBox?.put('show_tutorial', show);
    print('✅ Configuración tutorial: ${show ? 'Mostrar' : 'Ocultar'}');
  }

  /// Obtener configuración de mostrar tips en juego
  static bool getShowGameTips() {
    return _statsBox?.get('show_game_tips', defaultValue: true) ?? true;
  }

  /// Establecer si mostrar tips en juego
  static Future<void> setShowGameTips(bool show) async {
    await _statsBox?.put('show_game_tips', show);
    print('✅ Tips en juego: ${show ? 'Activados' : 'Desactivados'}');
  }

  /// Obtener configuración de mostrar pantalla de bienvenida
  static bool getShowWelcomeScreen() {
    return _statsBox?.get('show_welcome_screen', defaultValue: true) ?? true;
  }

  /// Establecer si mostrar pantalla de bienvenida
  static Future<void> setShowWelcomeScreen(bool show) async {
    await _statsBox?.put('show_welcome_screen', show);
    print('✅ Pantalla bienvenida: ${show ? 'Activada' : 'Desactivada'}');
  }

  /// Resetear todas las configuraciones de tutorial (para configuraciones)
  static Future<void> resetTutorialSettings() async {
    await _statsBox?.put('is_first_time', true);
    await _statsBox?.put('show_tutorial', true);
    await _statsBox?.put('show_game_tips', true);
    await _statsBox?.put('show_welcome_screen', true);
    print('🔄 Configuraciones de tutorial reseteadas');
  }

  /// 🧹 LIMPIEZA Y MANTENIMIENTO

  /// Limpiar datos de usuario (mantener configuraciones)
  static Future<void> clearUserData() async {
    await _userBox?.clear();
    print('🧹 Datos de usuario limpiados');
  }

  /// Limpiar todas las configuraciones
  static Future<void> clearSettings() async {
    await _settingsBox?.clear();
    print('🧹 Configuraciones limpiadas');
  }

  /// Backup completo de datos
  static Map<String, dynamic> exportData() {
    final currentUser = getCurrentUser();
    final settings = getSettings();
    
    return {
      'user': currentUser?.toString(),
      'settings': settings.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// � Establecer usuario actual
  static Future<void> setCurrentUser(LocalUser user) async {
    if (_userBox == null) {
      throw Exception('❌ Hive no inicializado');
    }
    
    await _userBox!.put('current_user', user);
    print('✅ Usuario establecido: ${user.name}');
  }

  /// �📱 INFORMACIÓN DEL SISTEMA

  /// Verificar si Hive está inicializado
  static bool get isInitialized {
    return _userBox != null && _settingsBox != null && _statsBox != null;
  }

  /// Obtener información de debug
  static Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': isInitialized,
      'users_count': _userBox?.length ?? 0,
      'settings_count': _settingsBox?.length ?? 0,
      'stats_count': _statsBox?.length ?? 0,
      'current_user': getCurrentUser()?.name ?? 'Ninguno',
    };
  }

  // 🎨 MÉTODOS PARA COLORES DE JUGADORES
  
  /// Guardar colores preferidos de jugadores
  static Future<void> savePlayerColors(List<int> colorIndices) async {
    try {
      await _statsBox?.put('player_colors', colorIndices);
      print('🎨 Colores de jugadores guardados: $colorIndices');
    } catch (e) {
      print('❌ Error guardando colores: $e');
    }
  }
  
  /// Obtener colores preferidos de jugadores
  static List<int> getPlayerColors() {
    try {
      final colors = _statsBox?.get('player_colors', defaultValue: [0, 1, 2, 3]) as List<dynamic>?;
      final result = colors?.cast<int>() ?? [0, 1, 2, 3]; // Rojo, Azul, Verde, Amarillo por defecto
      print('🎨 Colores de jugadores recuperados: $result');
      return result;
    } catch (e) {
      print('❌ Error recuperando colores: $e');
      return [0, 1, 2, 3]; // Valores por defecto
    }
  }
  
  /// Guardar orden de turnos aleatorio
  static Future<void> saveTurnOrder(List<int> turnOrder) async {
    try {
      await _statsBox?.put('turn_order', turnOrder);
      print('🎲 Orden de turnos guardado: $turnOrder');
    } catch (e) {
      print('❌ Error guardando orden de turnos: $e');
    }
  }
  
  /// Obtener orden de turnos
  static List<int> getTurnOrder() {
    try {
      final order = _statsBox?.get('turn_order', defaultValue: [0, 1, 2, 3]) as List<dynamic>?;
      final result = order?.cast<int>() ?? [0, 1, 2, 3];
      print('🎲 Orden de turnos recuperado: $result');
      return result;
    } catch (e) {
      print('❌ Error recuperando orden de turnos: $e');
      return [0, 1, 2, 3];
    }
  }

  /// 🔄 CERRAR HIVE (para testing)
  static Future<void> close() async {
    await _userBox?.close();
    await _settingsBox?.close();
    await _statsBox?.close();
    print('📦 Hive cerrado');
  }
}