import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/local_user.dart';
import 'hive_service.dart';

/// 🔐 AUTH SERVICE - Sistema de Autenticación Simplificado (Modo Local)
/// 
/// Funcionalidades actuales:
/// - ✅ Gestión de usuarios invitados
/// - ✅ Datos locales con Hive
/// - ⚠️  Firebase/Facebook/Google Login temporalmente deshabilitados
/// 
/// TODO: Configurar Firebase correctamente y restaurar funcionalidad cloud
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 📱 Estado actual
  LocalUser? _currentLocalUser;
  bool _isInitialized = false;

  // 🚀 Inicializar servicio
  static Future<void> initialize() async {
    try {
      // TODO: Configurar Firebase correctamente con firebase_options.dart
      // await Firebase.initializeApp();
      
      // Por ahora, trabajar solo en modo local
      AuthService()._isInitialized = true;
      
      // Asegurar que hay un usuario local
      await AuthService()._ensureLocalUser();
      
      print('✅ AuthService inicializado en modo local');
      print('⚠️  Firebase deshabilitado temporalmente');
    } catch (e) {
      print('❌ Error inicializando AuthService: $e');
      // Continuar en modo offline
      AuthService()._isInitialized = true;
    }
  }

  // 👤 Asegurar que existe un usuario local
  Future<void> _ensureLocalUser() async {
    LocalUser? user = HiveService.getCurrentUser();
    
    if (user == null) {
      // Crear usuario invitado por defecto
      await HiveService.createGuestUser();
      user = HiveService.getCurrentUser();
      print('🆔 Usuario invitado creado automáticamente');
    }
    
    _currentLocalUser = user;
    print('👤 Usuario actual: ${user?.name}');
  }

  // 📊 Login con Facebook (temporalmente deshabilitado)
  Future<LocalUser?> loginWithFacebook() async {
    print('⚠️  Facebook Login temporalmente deshabilitado');
    print('🔧 Necesita configuración Firebase completa');
    
    // Por ahora, solo mostrar mensaje informativo
    return _currentLocalUser;
  }

  // � Alias para compatibilidad con LoginScreen
  Future<LocalUser?> signInWithFacebook() async {
    return await loginWithFacebook();
  }

  // �🔍 Login con Google (temporalmente deshabilitado)
  Future<LocalUser?> loginWithGoogle() async {
    print('⚠️  Google Login temporalmente deshabilitado');
    print('🔧 Necesita configuración Firebase completa');
    
    // Por ahora, solo mostrar mensaje informativo
    return _currentLocalUser;
  }

  // 🔍 Alias para compatibilidad con LoginScreen
  Future<LocalUser?> signInWithGoogle() async {
    return await loginWithGoogle();
  }

  // 🚪 Logout
  Future<void> logout() async {
    try {
      print('🚪 Cerrando sesión...');
      
      // TODO: Logout de Firebase cuando esté configurado
      // await _auth.signOut();
      // await _googleSignIn.signOut();
      // await FacebookAuth.instance.logOut();
      
      // Crear nuevo usuario invitado
      await HiveService.clearUserData();
      await HiveService.createGuestUser();
      _currentLocalUser = HiveService.getCurrentUser();
      
      print('✅ Sesión cerrada - Nuevo usuario invitado creado');
    } catch (e) {
      print('❌ Error en logout: $e');
    }
  }

  // 🌐 Verificar conectividad
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // 📱 Getters
  bool get isInitialized => _isInitialized;
  LocalUser? get currentLocalUser => _currentLocalUser;
  bool get isLoggedIn => _currentLocalUser != null && !_currentLocalUser!.isGuest;
  bool get isGuest => _currentLocalUser?.isGuest ?? true;
  String? get userEmail => _currentLocalUser?.email;

  // ✅ Verificar si está autenticado
  bool get isAuthenticated => _isInitialized && _currentLocalUser != null;

  // 🔄 Refrescar usuario actual
  Future<void> refreshCurrentUser() async {
    _currentLocalUser = HiveService.getCurrentUser();
  }

  // 📝 Actualizar nombre de usuario
  Future<void> updateUserName(String newName) async {
    if (_currentLocalUser != null) {
      _currentLocalUser!.name = newName;
      await HiveService.saveCurrentUser(_currentLocalUser!);
      print('✅ Nombre actualizado: $newName');
    }
  }

  // 📝 Alias para compatibilidad con SettingsScreen
  Future<void> updateNickname(String newName) async {
    await updateUserName(newName);
  }

  // 🎮 Registrar victoria
  Future<void> recordWin() async {
    if (_currentLocalUser != null) {
      _currentLocalUser!.recordWin();
      await HiveService.saveCurrentUser(_currentLocalUser!);
    }
  }

  // 😞 Registrar derrota
  Future<void> recordLoss() async {
    if (_currentLocalUser != null) {
      _currentLocalUser!.recordLoss();
      await HiveService.saveCurrentUser(_currentLocalUser!);
    }
  }

  // 🏆 Agregar logro
  Future<void> addAchievement(String achievement) async {
    if (_currentLocalUser != null) {
      _currentLocalUser!.addAchievement(achievement);
      await HiveService.saveCurrentUser(_currentLocalUser!);
    }
  }

  // 📊 Debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _isInitialized,
      'current_user': _currentLocalUser?.name,
      'is_guest': _currentLocalUser?.isGuest,
      'games_played': _currentLocalUser?.gamesPlayed,
      'win_rate': _currentLocalUser?.winRate,
      'firebase_enabled': false, // Temporalmente deshabilitado
    };
  }
}