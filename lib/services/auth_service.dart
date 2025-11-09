import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/local_user.dart';
import 'hive_service.dart';

/// 🔐 AUTH SERVICE - Sistema de Autenticación Simplificado (Solo Local)
/// 
/// Funcionalidades:
/// - ✅ Gestión de usuarios invitados
/// - ✅ Datos locales con Hive
/// - ✅ Sistema completamente offline
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 📱 Estado actual
  LocalUser? _currentLocalUser;

  // 🚀 Inicializar servicio
  static Future<void> initialize() async {
    try {
      // Solo modo local - sin dependencias cloud
      
      // Asegurar que hay un usuario local
      await AuthService()._ensureLocalUser();
      
      print('✅ AuthService inicializado en modo local');
    } catch (e) {
      print('❌ Error inicializando AuthService: $e');
      // Continuar en modo offline
    }
  }

  // 👤 Asegurar que existe un usuario local
  Future<void> _ensureLocalUser() async {
    LocalUser? user = HiveService.getCurrentUser();
    if (user != null) {
      _currentLocalUser = user;
      print('👤 Usuario actual: ${user.name}');
    } else {
      // Crear usuario invitado automáticamente
      await _createGuestUser();
      _currentLocalUser = HiveService.getCurrentUser();
      print('👤 Usuario invitado creado automáticamente');
    }
  }

  // 🆕 Crear usuario invitado
  Future<void> _createGuestUser() async {
    final user = LocalUser(
      name: 'Invitado ${DateTime.now().millisecondsSinceEpoch % 10000}',
      email: 'guest@local.com',
      isGuest: true,
    );
    await HiveService.setCurrentUser(user);
  }

  // 🚪 Logout
  Future<void> logout() async {
    try {
      print('🚪 Cerrando sesión...');
      
      // Crear nuevo usuario invitado
      await _createGuestUser();
      _currentLocalUser = HiveService.getCurrentUser();
      
      print('✅ Nueva sesión de invitado iniciada');
    } catch (e) {
      print('❌ Error en logout: $e');
    }
  }

  // 👤 Obtener usuario actual
  LocalUser? get currentUser => _currentLocalUser ?? HiveService.getCurrentUser();

  // ✅ Verificar si está autenticado
  bool get isAuthenticated => currentUser != null;

  // 👤 Verificar si es invitado
  bool get isGuest => currentUser?.isGuest ?? true;

  // 🔐 Verificar si está logueado (alias)
  bool get isLoggedIn => isAuthenticated;

  // 📧 Email del usuario
  String? get userEmail => currentUser?.email;

  // 🔄 Actualizar nickname
  Future<void> updateNickname(String newName) async {
    final user = currentUser;
    if (user != null) {
      user.name = newName;
      await user.save();
      _currentLocalUser = user;
      print('✅ Nickname actualizado: $newName');
    }
  }

  // 📱 Login con Facebook (stub)
  Future<LocalUser?> signInWithFacebook() async {
    print('ℹ️ Facebook login no disponible en modo local');
    return currentUser;
  }

  // 🔍 Login con Google (stub)  
  Future<LocalUser?> signInWithGoogle() async {
    print('ℹ️ Google login no disponible en modo local');
    return currentUser;
  }

  // 🌐 Verificar conectividad
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('❌ Error verificando conectividad: $e');
      return false;
    }
  }

  // 🎮 Login como invitado (método principal)
  Future<LocalUser?> loginAsGuest() async {
    try {
      await _createGuestUser();
      _currentLocalUser = HiveService.getCurrentUser();
      return _currentLocalUser;
    } catch (e) {
      print('❌ Error en login de invitado: $e');
      return null;
    }
  }

  // 👤 Obtener perfil de usuario actual
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = currentUser;
    
    if (user == null) {
      return {
        'error': 'No hay usuario autenticado',
        'authenticated': false,
      };
    }
    
    return {
      'authenticated': true,
      'user_id': user.name, // Usar name como ID único
      'display_name': user.name,
      'email': user.email ?? 'invitado@local.com',
      'is_guest': user.isGuest,
      'total_games': user.gamesPlayed,
      'games_won': user.gamesWon,
      'games_lost': user.gamesLost,
      'win_rate': user.winRate,
      'current_streak': user.currentStreak,
      'max_streak': user.bestStreak,
      'achievements': user.achievements,
      'last_login': user.lastLoginDate?.toIso8601String(),
    };
  }

  // 🔄 Actualizar último acceso
  Future<void> updateLastSeen() async {
    final user = currentUser;
    if (user != null) {
      user.updateLoginDate();
      _currentLocalUser = user;
    }
  }
}