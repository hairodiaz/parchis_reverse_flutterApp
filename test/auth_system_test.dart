import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import 'package:parchis_reverse_app/models/local_user.dart';
import 'package:parchis_reverse_app/models/game_settings.dart';

/// Versión simplificada de HiveService para tests
class TestHiveService {
  static const String _userBoxName = 'users';
  static const String _settingsBoxName = 'settings';

  static Box<LocalUser>? _userBox;
  static Box<GameSettings>? _settingsBox;

  static Future<void> init() async {
    try {
      Hive.registerAdapter(LocalUserAdapter());
      Hive.registerAdapter(GameSettingsAdapter());

      _userBox = await Hive.openBox<LocalUser>(_userBoxName);
      _settingsBox = await Hive.openBox<GameSettings>(_settingsBoxName);

      print('✅ Test Hive inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando Test Hive: $e');
      rethrow;
    }
  }

  static LocalUser? getCurrentUser() {
    return _userBox?.get('current_user');
  }

  static Future<void> saveCurrentUser(LocalUser user) async {
    await _userBox?.put('current_user', user);
  }

  static Future<void> createGuestUser() async {
    final guestNumber = DateTime.now().millisecondsSinceEpoch % 100;
    final guestUser = LocalUser(
      name: 'Invitado$guestNumber',
      isGuest: true,
      achievements: <String>[], // Lista mutable explícita
    );
    await saveCurrentUser(guestUser);
  }

  static GameSettings getSettings() {
    return _settingsBox?.get('game_settings') ?? GameSettings();
  }

  static Future<void> saveSettings(GameSettings settings) async {
    await _settingsBox?.put('game_settings', settings);
  }

  static Future<void> clearUserData() async {
    await _userBox?.clear();
  }

  static Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': true,
      'users_count': _userBox?.length ?? 0,
      'settings_count': _settingsBox?.length ?? 0,
      'current_user': getCurrentUser()?.name ?? 'null',
    };
  }
}

void main() {
  group('🔐 Tests de Autenticación', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      final tempDir = Directory.systemTemp.createTempSync('test_hive');
      Hive.init(tempDir.path);
      
      await TestHiveService.init();
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
    });

    test('🆔 Usuario Invitado - Debe crear usuario invitado por defecto', () async {
      print('🧪 TEST 1: Creación de usuario invitado');
      
      // Limpiar datos existentes
      await TestHiveService.clearUserData();
      
      // Crear usuario invitado
      await TestHiveService.createGuestUser();
      
      // Verificar usuario creado
      final user = TestHiveService.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.isGuest, isTrue);
      expect(user.name.startsWith('Invitado'), isTrue);
      expect(user.gamesPlayed, equals(0));
      expect(user.gamesWon, equals(0));
      
      print('✅ Usuario invitado creado: ${user.name}');
    });

    test('👤 Nickname Personalizado - Debe permitir cambiar nombre', () async {
      print('🧪 TEST 2: Cambio de nickname');
      
      final user = TestHiveService.getCurrentUser();
      expect(user, isNotNull);
      
      const nuevoNombre = 'TestUser123';
      user!.name = nuevoNombre;
      await TestHiveService.saveCurrentUser(user);
      
      // Verificar cambio persistido
      final userUpdated = TestHiveService.getCurrentUser();
      expect(userUpdated!.name, equals(nuevoNombre));
      
      print('✅ Nickname actualizado: ${userUpdated.name}');
    });

    test('🎮 Estadísticas - Debe registrar partidas correctamente', () async {
      print('🧪 TEST 3: Sistema de estadísticas');
      
      final user = TestHiveService.getCurrentUser();
      expect(user, isNotNull);
      
      // Estado inicial
      expect(user!.gamesPlayed, equals(0));
      expect(user.gamesWon, equals(0));
      expect(user.winRate, equals(0.0));
      
      // Registrar victoria
      user.recordWin();
      await TestHiveService.saveCurrentUser(user);
      
      // Verificar estadísticas
      final userAfterWin = TestHiveService.getCurrentUser();
      expect(userAfterWin!.gamesPlayed, equals(1));
      expect(userAfterWin.gamesWon, equals(1));
      expect(userAfterWin.winRate, equals(100.0)); // winRate es porcentaje, no fracción
      expect(userAfterWin.currentStreak, equals(1));
      
      // Registrar derrota
      user.recordLoss();
      await TestHiveService.saveCurrentUser(user);
      
      // Verificar estadísticas después de derrota
      final userAfterLoss = TestHiveService.getCurrentUser();
      expect(userAfterLoss!.gamesPlayed, equals(2));
      expect(userAfterLoss.gamesWon, equals(1));
      expect(userAfterLoss.winRate, equals(50.0)); // 50% como porcentaje
      expect(userAfterLoss.currentStreak, equals(0));
      
      print('✅ Estadísticas funcionando: ${userAfterLoss.gamesPlayed} partidas, ${userAfterLoss.winRate}% winrate');
    });

    test('🏆 Logros - Debe gestionar achievements', () async {
      print('🧪 TEST 4: Sistema de logros');
      
      final user = TestHiveService.getCurrentUser();
      expect(user, isNotNull);
      
      // Estado inicial - sin logros
      expect(user!.achievements.length, equals(0));
      
      // Agregar logros
      user.addAchievement('Primera Victoria');
      user.addAchievement('Racha de 5');
      await TestHiveService.saveCurrentUser(user);
      
      // Verificar logros
      final userWithAchievements = TestHiveService.getCurrentUser();
      expect(userWithAchievements!.achievements.length, equals(2));
      expect(userWithAchievements.achievements.contains('Primera Victoria'), isTrue);
      expect(userWithAchievements.achievements.contains('Racha de 5'), isTrue);
      
      // Verificar que no se duplican logros
      user.addAchievement('Primera Victoria'); // Duplicado
      await TestHiveService.saveCurrentUser(user);
      
      final userNoDuplicates = TestHiveService.getCurrentUser();
      expect(userNoDuplicates!.achievements.length, equals(2)); // No debe aumentar
      
      print('✅ Logros gestionados correctamente: ${userNoDuplicates.achievements}');
    });

    test('⚙️ Configuraciones - Debe persistir configuraciones', () async {
      print('🧪 TEST 5: Sistema de configuraciones');
      
      // Configuraciones por defecto
      var settings = TestHiveService.getSettings();
      expect(settings.musicVolume, equals(0.7));
      expect(settings.effectsVolume, equals(0.8));
      expect(settings.vibrationEnabled, isTrue);
      
      // Cambiar configuraciones
      settings.musicVolume = 0.5;
      settings.effectsVolume = 0.3;
      settings.vibrationEnabled = false;
      settings.theme = 'dark';
      settings.language = 'en';
      
      await TestHiveService.saveSettings(settings);
      
      // Verificar persistencia
      final savedSettings = TestHiveService.getSettings();
      expect(savedSettings.musicVolume, equals(0.5));
      expect(savedSettings.effectsVolume, equals(0.3));
      expect(savedSettings.vibrationEnabled, isFalse);
      expect(savedSettings.theme, equals('dark'));
      expect(savedSettings.language, equals('en'));
      
      print('✅ Configuraciones persistidas correctamente');
    });

    test('📊 Debug Info - Debe proporcionar información del sistema', () async {
      print('🧪 TEST 6: Información de debug');
      
      final debugInfo = TestHiveService.getDebugInfo();
      
      expect(debugInfo['initialized'], isTrue);
      expect(debugInfo['users_count'], greaterThanOrEqualTo(1));
      expect(debugInfo['settings_count'], greaterThanOrEqualTo(0));
      expect(debugInfo['current_user'], isNotNull);
      
      print('✅ Debug info: $debugInfo');
    });

    test('🔄 Migración de Usuario - Debe simular migración a registrado', () async {
      print('🧪 TEST 7: Simulación de migración');
      
      final guestUser = TestHiveService.getCurrentUser();
      expect(guestUser, isNotNull);
      expect(guestUser!.isGuest, isTrue);
      
      // Simular registro - convertir invitado a registrado
      final registeredUser = LocalUser(
        name: guestUser.name,
        facebookId: 'test_facebook_id_123',
        email: 'test@example.com',
        isGuest: false,
        gamesWon: guestUser.gamesWon,
        gamesPlayed: guestUser.gamesPlayed,
        currentStreak: guestUser.currentStreak,
        bestStreak: guestUser.bestStreak,
        achievements: List<String>.from(guestUser.achievements), // Lista mutable
      );
      
      await TestHiveService.saveCurrentUser(registeredUser);
      
      // Verificar migración
      final migratedUser = TestHiveService.getCurrentUser();
      expect(migratedUser, isNotNull);
      expect(migratedUser!.isGuest, isFalse);
      expect(migratedUser.facebookId, equals('test_facebook_id_123'));
      expect(migratedUser.email, equals('test@example.com'));
      expect(migratedUser.name, equals(guestUser.name)); // Nombre preservado
      expect(migratedUser.gamesPlayed, equals(guestUser.gamesPlayed)); // Stats preservadas
      
      print('✅ Migración simulada: ${migratedUser.name} (${migratedUser.email})');
    });

    test('🧹 Limpieza y Recreación - Debe manejar reset completo', () async {
      print('🧪 TEST 8: Reset del sistema');
      
      // Verificar que hay datos
      var user = TestHiveService.getCurrentUser();
      expect(user, isNotNull);
      
      // Limpiar todo
      await TestHiveService.clearUserData();
      
      // Verificar limpieza
      user = TestHiveService.getCurrentUser();
      expect(user, isNull);
      
      // Recrear usuario invitado
      await TestHiveService.createGuestUser();
      
      // Verificar recreación
      user = TestHiveService.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.isGuest, isTrue);
      expect(user.gamesPlayed, equals(0));
      
      print('✅ Sistema reseteado y recreado correctamente');
    });
  });
}