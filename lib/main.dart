import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // 📱 MANTENER PANTALLA ACTIVA
import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'services/audio_service.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/intro_screen.dart'; // 🎬 NUEVA PANTALLA DE INTRO
import 'screens/instructions_screen.dart'; // 📚 PANTALLA DE INSTRUCCIONES

// Enum para prioridades de mensajes
enum MessagePriority {
  critical, // Mensajes críticos (3 seises, eliminación) - no pueden ser interrumpidos
  high,     // Mensajes importantes (llegada a META, capturas)
  normal,   // Mensajes normales (turnos extra, dice results)
  special   // Mensajes de casillas especiales (pueden ser largos)
}

// 📬 CLASE PARA DATOS DE MENSAJE
class MessageData {
  final String text;
  final MessagePriority priority;
  final int durationSeconds;
  final DateTime timestamp;
  
  MessageData(this.text, this.priority, this.durationSeconds) 
    : timestamp = DateTime.now();
}

// 🎯 SISTEMA DE COLA DE MENSAJES - EVITA CANCELACIONES PREMATURAS
class MessageQueue {
  final List<MessageData> _queue = [];
  bool _isProcessing = false;
  Timer? _currentMessageTimer;
  Function(MessageData)? onDisplayMessage;
  Function()? onClearMessage;
  
  // Agregar mensaje a la cola
  void addMessage(String text, MessagePriority priority, int durationSeconds) {
    final message = MessageData(text, priority, durationSeconds);
    
    // 🚨 CRÍTICOS interrumpen todo inmediatamente
    if (priority == MessagePriority.critical) {
      _queue.insert(0, message); // Insertar al principio
      if (_isProcessing) {
        _currentMessageTimer?.cancel();
        _isProcessing = false;
      }
    } else {
      _queue.add(message); // Agregar al final
    }
    
    if (!_isProcessing) {
      _processNextMessage();
    }
  }
  
  // Procesar siguiente mensaje en la cola
  void _processNextMessage() async {
    if (_queue.isEmpty) {
      _isProcessing = false;
      onClearMessage?.call();
      return;
    }
    
    _isProcessing = true;
    final message = _queue.removeAt(0);
    
    // Mostrar mensaje
    onDisplayMessage?.call(message);
    
    // Esperar duración completa del mensaje
    _currentMessageTimer = Timer(Duration(seconds: message.durationSeconds), () {
      _processNextMessage(); // Procesar siguiente
    });
  }
  
  // Limpiar toda la cola (solo para emergencias)
  void clear() {
    _currentMessageTimer?.cancel();
    _queue.clear();
    _isProcessing = false;
    onClearMessage?.call();
  }
}

// Clase para representar la posición en el tablero
class Position {
  final int row;
  final int col;
  
  const Position(this.row, this.col);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && runtimeType == other.runtimeType && row == other.row && col == other.col;
  
  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

// Clase para representar una ficha del juego
class GamePiece {
  final String id;
  final Color color;
  Position position;
  
  GamePiece({
    required this.id,
    required this.color,
    required this.position,
  });
}

void main() async {
  // 🚀 Inicializar Flutter y Hive
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 🗂️ Inicializar base de datos local (Hive)
    await HiveService.init();
    print('✅ Base de datos local inicializada correctamente');
    
    // 🔐 Inicializar servicio de autenticación
    await AuthService.initialize();
    print('✅ Servicio de autenticación inicializado');
    
    // 🎵 Inicializar servicio de audio
    await AudioService().initialize();
    print('✅ Servicio de audio inicializado');
    
    // 👤 Crear usuario por defecto si no existe
    if (HiveService.getCurrentUser() == null) {
      await AuthService().loginAsGuest();
      print('👤 Usuario invitado creado por defecto');
    }
    
    // 🐛 Información de debug
    print('📊 Debug Info: ${HiveService.getDebugInfo()}');
  } catch (e) {
    print('❌ Error inicializando base de datos: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parchís Reverse Dominicano',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const IntroScreen(), // 🎬 INICIAR CON VIDEO DE INTRO
      routes: {
        '/main': (context) => const MainMenuScreen(),
        '/login': (context) => const LoginScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

//  PANTALLA PRINCIPAL DEL MENÚ - ¡PROFESIONAL!
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _buttonsController;
  late AnimationController _floatingController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _buttonsAnimation;
  late Animation<double> _floatingAnimation;
  
  // 🎠 CAROUSEL VARIABLES
  late PageController _carouselController;
  int _currentGameMode = 0;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // 🎠 Inicializar carousel controller
    _carouselController = PageController(initialPage: 0, viewportFraction: 0.8);
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    _buttonsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.elasticOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    _startAnimations();
    
    // 🎵 INICIAR MÚSICA DE FONDO DEL MENÚ
    _startBackgroundMusic();
    
    // 📚 VERIFICAR SI MOSTRAR TUTORIAL DE BIENVENIDA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser();
    });
  }
  
  void _startAnimations() async {
    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _buttonsController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _floatingController.repeat(reverse: true);
  }
  
  // 🎵 INICIAR MÚSICA DE FONDO DEL MENÚ
  void _startBackgroundMusic() async {
    try {
      // Esperar un poco para que se carguen las animaciones
      await Future.delayed(const Duration(milliseconds: 1000));
      await AudioService().playBackgroundMusic('background.mp3');
      print('🎵 Música de fondo iniciada en el menú principal');
    } catch (e) {
      print('❌ Error iniciando música de fondo: $e');
    }
  }
  
  // 📚 VERIFICAR SI ES PRIMERA VEZ DEL USUARIO
  void _checkFirstTimeUser() {
    if (HiveService.isFirstTime() && HiveService.getShowWelcomeScreen()) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _showWelcomeTutorial();
      });
    }
  }
  
  // 🎉 MOSTRAR DIÁLOGO DE BIENVENIDA
  void _showWelcomeTutorial() {
    bool dontShowAgain = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1a237e),
          title: const Row(
            children: [
              Icon(Icons.waving_hand, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Bienvenido al Parchís Reverse!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 Esta es una versión moderna del clásico juego dominicano con nuevas mecánicas y efectos especiales.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Te gustaría ver las instrucciones antes de empezar tu primera partida?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              // Checkbox "No mostrar más"
              InkWell(
                onTap: () {
                  setDialogState(() {
                    dontShowAgain = !dontShowAgain;
                  });
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: dontShowAgain,
                        onChanged: (value) {
                          setDialogState(() {
                            dontShowAgain = value ?? false;
                          });
                        },
                        activeColor: Colors.amber,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No mostrar esta bienvenida nuevamente',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _handleWelcomeChoice(false, dontShowAgain);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Empezar Jugando'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _handleWelcomeChoice(true, dontShowAgain);
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InstructionsScreen(showAsFirstTime: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Ver Tutorial',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 🎯 MANEJAR ELECCIÓN DEL USUARIO EN BIENVENIDA
  void _handleWelcomeChoice(bool viewedTutorial, bool dontShowAgain) {
    // Marcar como usuario experimentado
    HiveService.setNotFirstTime();
    
    // Si eligió no mostrar más, guardar preferencia
    if (dontShowAgain) {
      HiveService.setShowWelcomeScreen(false);
    }
    
    print('📚 Bienvenida procesada - Tutorial: $viewedTutorial, No mostrar: $dontShowAgain');
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _buttonsController.dispose();
    _floatingController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF6A1B9A), const Color(0xFF8E24AA), _backgroundAnimation.value)!,
                  Color.lerp(const Color(0xFF8E24AA), const Color(0xFF9C27B0), _backgroundAnimation.value)!,
                  Color.lerp(const Color(0xFF9C27B0), const Color(0xFFAB47BC), _backgroundAnimation.value)!,
                  Color.lerp(const Color(0xFFAB47BC), const Color(0xFF7B1FA2), _backgroundAnimation.value)!,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // 🔝 TOP BAR CON ICONOS
                  _buildTopBar(),
                  
                  // 📱 CONTENIDO PRINCIPAL
                  Column(
                    children: [
                      // 🎯 LOGO Y TÍTULO (más compacto)
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.06,
                          bottom: 15,
                        ),
                    child: FadeTransition(
                      opacity: _backgroundAnimation,
                      child: Column(
                        children: [
                          // Logo animado (más pequeño)
                          AnimatedBuilder(
                            animation: _floatingAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_floatingAnimation.value * 0.01),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 12 + (_floatingAnimation.value * 0.3),
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.casino,
                                    size: 35,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Título compacto
                          const Text(
                            '🎲 PARCHÍS REVERSE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  blurRadius: 12.0,
                                  color: Colors.black45,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const Text(
                            'DOMINICANO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFD700),
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(
                                  blurRadius: 6.0,
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 🎠 CAROUSEL DE MODOS DE JUEGO
                      Expanded(
                        flex: 2,
                        child: _buildGameModeCarousel(),
                      ),
                      
                      // 👤 PERFIL DE USUARIO (expandido)
                      Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          child: FadeTransition(
                            opacity: _backgroundAnimation,
                            child: _buildExpandedUserProfile(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }






  void _showUserProfileDetails() {
    final user = HiveService.getCurrentUser();
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el perfil del usuario')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nivel ${(user.gamesWon ~/ 5) + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Estado del usuario
              _buildProfileSection(
                title: '👤 Estado del Usuario',
                items: [
                  _buildProfileRow('Tipo:', user.isGuest ? 'Usuario Invitado' : 'Usuario Registrado'),
                  if (user.lastLoginDate != null)
                    _buildProfileRow('Último acceso:', _formatDate(user.lastLoginDate!)),
                  if (user.email != null)
                    _buildProfileRow('Email:', user.email!),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Estadísticas de juego
              _buildProfileSection(
                title: '📊 Estadísticas de Juego',
                items: [
                  _buildProfileRow('Partidas jugadas:', '${user.gamesPlayed}'),
                  _buildProfileRow('Partidas ganadas:', '${user.gamesWon}'),
                  _buildProfileRow('Partidas perdidas:', '${user.gamesPlayed - user.gamesWon}'),
                  _buildProfileRow('Porcentaje de victoria:', '${user.winRate.toStringAsFixed(1)}%'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Rachas y logros
              _buildProfileSection(
                title: '🏆 Rachas y Logros',
                items: [
                  _buildProfileRow('Racha actual:', '${user.currentStreak} victorias'),
                  _buildProfileRow('Mejor racha:', '${user.bestStreak} victorias'),
                  _buildProfileRow('Logros obtenidos:', '${user.achievements.length}'),
                ],
              ),
              
              if (user.achievements.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildAchievementsSection(user.achievements),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods para el perfil de usuario
  Widget _buildProfileSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(List<String> achievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏅 Logros Desbloqueados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: achievements.isEmpty
              ? const Text(
                  'Aún no has desbloqueado logros. ¡Sigue jugando!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: achievements.map((achievement) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        achievement,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.casino,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Acerca de',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del juego
              const Text(
                '🎲 Parchís Reverse Dominicano',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Versión 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Información del desarrollador
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6A1B9A).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '👨‍💻',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Desarrollado por:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ing. Hairo Díaz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '� Ingeniero en Sistemas de Información',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Historia personal
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🌟', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                'Mi Historia:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '💻 Adicto a la programación.\n'
                            '🎮 Fanático de los videojuegos.\n'
                            '🌟 El desarrollo de videojuegos es mi sueño.\n'
                            '🇩🇴 Dominicano viviendo en Estados Unidos.\n'
                            '🆕 ¡Este es mi primer videojuego!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Tecnología
                    Text(
                      '🛠️ Tecnología:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Desarrollado con Flutter & Dart\nOptimizado para iOS y Android',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Visión del proyecto
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          'Visión del Proyecto:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preservar y modernizar el tradicional juego dominicano del Parchís, '
                      'llevando nuestra cultura al mundo digital con una experiencia '
                      'inmersiva y divertida para todas las edades.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Footer con corazón
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.red[400],
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hecho con pasión y orgullo dominicano 🇩🇴',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Agradecimientos
              Text(
                '✨ Gracias por jugar y apoyar mi primer videojuego',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: Color(0xFF6A1B9A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información'),
        content: const Text('Funcionalidad simplificada con sistema Hive local.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // 🔝 TOP BAR CON ICONOS FLOTANTES
  Widget _buildTopBar() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _backgroundAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ⚙️ CONFIGURACIONES (izquierda)
              _buildTopIcon(
                icon: Icons.settings_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              
              // ℹ️ ACERCA DE + 🚪 SALIR (derecha)
              Row(
                children: [
                  _buildTopIcon(
                    icon: Icons.info_outline_rounded,
                    onTap: _showAboutDialog,
                  ),
                  const SizedBox(width: 15),
                  _buildTopIcon(
                    icon: Icons.logout_rounded,
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔘 ICONO DEL TOP BAR
  Widget _buildTopIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // 🎠 CAROUSEL DE MODOS DE JUEGO
  Widget _buildGameModeCarousel() {
    final gameModes = [
      {'icon': Icons.play_arrow_rounded, 'title': 'CLÁSICO', 'subtitle': 'Modo tradicional', 'available': true},
      {'icon': Icons.emoji_events, 'title': 'RANKED', 'subtitle': 'Competitivo', 'available': false},
      {'icon': Icons.public, 'title': 'ONLINE', 'subtitle': 'Multijugador', 'available': false},
      {'icon': Icons.emoji_events_outlined, 'title': 'TORNEO', 'subtitle': 'Eliminación', 'available': false},
    ];

    return Column(
      children: [
        // Carousel
        Expanded(
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() {
                _currentGameMode = index;
              });
            },
            itemCount: gameModes.length,
            itemBuilder: (context, index) {
              final mode = gameModes[index];
              return _buildGameModeCard(
                icon: mode['icon'] as IconData,
                title: mode['title'] as String,
                subtitle: mode['subtitle'] as String,
                available: mode['available'] as bool,
                isActive: index == _currentGameMode,
              );
            },
          ),
        ),
        
        // Indicadores de página
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            gameModes.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentGameMode == index ? 12 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentGameMode == index 
                    ? const Color(0xFFFFD700) 
                    : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🎮 TARJETA DE MODO DE JUEGO
  Widget _buildGameModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool available,
    required bool isActive,
  }) {
    return AnimatedBuilder(
      animation: _buttonsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonsAnimation.value * (isActive ? 1.0 : 0.9),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Material(
              elevation: isActive ? 12 : 6,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () {
                  if (available) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlayerConfigScreen()),
                    );
                  } else {
                    _showComingSoonDialog(title);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: available 
                          ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                          : [Colors.grey.shade400, Colors.grey.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          icon,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      
                      if (!available) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: const Text(
                            'Próximamente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      
                      // 📚 BOTÓN DE INSTRUCCIONES SOLO EN MODO CLÁSICO
                      if (available && title == 'CLÁSICO') ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InstructionsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.help_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            '¿Cómo Jugar?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            side: const BorderSide(color: Colors.white, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 📢 DIÁLOGO "PRÓXIMAMENTE"
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 12),
            Text('Próximamente'),
          ],
        ),
        content: Text(
          'La función "$feature" estará disponible en futuras actualizaciones.\n\n¡Mantente atento!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Entendido',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👤 PERFIL DE USUARIO EXPANDIDO  
  Widget _buildExpandedUserProfile() {
    final user = HiveService.getCurrentUser();
    
    if (user == null) {
      return const Center(child: Text('No hay usuario'));
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar y nombre
            Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${user.name}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'Nivel ${(user.gamesWon ~/ 5) + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Estadísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.emoji_events,
                label: 'Ganadas',
                value: '${user.gamesWon}',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.sports_esports,
                label: 'Jugadas',
                value: '${user.gamesPlayed}',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                label: 'Racha',
                value: '${user.currentStreak}',
                color: Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Botón ver detalles
          GestureDetector(
            onTap: _showUserProfileDetails,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ver detalles completos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  // 📊 ITEM DE ESTADÍSTICA
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

// ⚙️ PANTALLA DE CONFIGURACIÓN DE JUGADORES
class PlayerConfigScreen extends StatefulWidget {
  const PlayerConfigScreen({super.key});

  @override
  State<PlayerConfigScreen> createState() => _PlayerConfigScreenState();
}

class _PlayerConfigScreenState extends State<PlayerConfigScreen> {
  int numPlayers = 4;
  List<String> playerNames = ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'];
  List<bool> isHuman = [true, true, true, true]; // true = humano, false = CPU
  List<Color> availableColors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
  List<String> colorNames = ['Rojo', 'Azul', 'Verde', 'Amarillo'];
  List<int> selectedColorIndices = [0, 1, 2, 3]; // Índices de colores seleccionados por cada jugador

  @override
  void initState() {
    super.initState();
    
    // Cargar configuraciones guardadas
    _loadUserName();
    _loadPlayerColors();
  }
  
  void _loadUserName() {
    final user = HiveService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        playerNames[0] = user.name;
      });
    }
  }
  
  void _loadPlayerColors() {
    final savedColors = HiveService.getPlayerColors();
    if (mounted) {
      setState(() {
        selectedColorIndices = savedColors;
      });
    }
  }
  
  void _showColorPicker(int playerIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎨 Seleccionar Color para ${playerNames[playerIndex]}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 320, // Aumentado de 200 a 320
          height: 260, // Aumentado de 100 a 200
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16, // Aumentado de 8 a 16
              crossAxisSpacing: 16, // Aumentado de 8 a 16
              childAspectRatio: 1.1, // Hacer los elementos un poco más altos
            ),
            itemCount: availableColors.length,
            itemBuilder: (context, colorIndex) {
              final isSelected = selectedColorIndices[playerIndex] == colorIndex;
              final isUsedByOther = selectedColorIndices.contains(colorIndex) && 
                                   selectedColorIndices[playerIndex] != colorIndex;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isUsedByOther) {
                      // 🔄 INTERCAMBIO AUTOMÁTICO DE COLORES
                      int otherPlayerIndex = selectedColorIndices.indexOf(colorIndex);
                      int myCurrentColor = selectedColorIndices[playerIndex];
                      
                      // Hacer el intercambio
                      selectedColorIndices[playerIndex] = colorIndex;
                      selectedColorIndices[otherPlayerIndex] = myCurrentColor;
                      
                      // Mostrar mensaje de intercambio
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🔄 Intercambio: ${playerNames[playerIndex]} ↔ ${playerNames[otherPlayerIndex]}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.blue,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      // Selección normal
                      selectedColorIndices[playerIndex] = colorIndex;
                    }
                  });
                  
                  HiveService.savePlayerColors(selectedColorIndices);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: availableColors[colorIndex],
                    borderRadius: BorderRadius.circular(15), // Aumentado de 10 a 15
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white
                          : Colors.black54,
                      width: isSelected ? 4 : 3, // Aumentado el grosor del borde
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: availableColors[colorIndex].withOpacity(0.6), // Más opacidad
                        spreadRadius: 2, // Aumentado de 1 a 2
                        blurRadius: 8, // Aumentado de 6 a 8
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected 
                              ? Icons.check_circle
                              : (isUsedByOther ? Icons.swap_horiz : Icons.circle),
                          color: Colors.white,
                          size: 28, // Aumentado de 20 a 28
                        ),
                        const SizedBox(height: 4), // Aumentado de 2 a 4
                        Text(
                          colorNames[colorIndex],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12, // Aumentado de 9 a 12
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        if (isUsedByOther)
                          const Text(
                            'Intercambiar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9, // Aumentado de 7 a 9
                              fontStyle: FontStyle.italic,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '❌ Cancelar',
                style: TextStyle(
                  fontSize: 16, // Aumentado de 14 a 16
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.blue, // Color predeterminado
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  playerNames[0][0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  ),
                ),
              ),
            const Text(
              'Configuración de Partida',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 4,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5DC), // Beige claro
              Color(0xFFD2B48C), // Tan
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Título
                const Text(
                  '⚙️ CONFIGURACIÓN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Configura tu partida',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8D6E63),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Selector de cantidad de jugadores
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '👥 Cantidad de Jugadores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [2, 3, 4].map((count) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                numPlayers = count;
                              });
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: numPlayers == count 
                                    ? const Color(0xFF1976D2)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: numPlayers == count 
                                      ? const Color(0xFF0D47A1)
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: numPlayers == count 
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Lista de jugadores
                Expanded(
                  child: ListView.builder(
                    itemCount: numPlayers,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Color del jugador
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: availableColors[selectedColorIndices[index]],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Nombre del jugador
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    colorNames[index],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextField(
                                    enabled: false, // Siempre está el usuario en Jugador 1
                                    decoration: InputDecoration(
                                      hintText: index == 0 
                                          ? '👤 Usuario logueado' 
                                          : 'Nombre del jugador',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      suffixIcon: index == 0 
                                          ? Icon(
                                              Icons.lock_outline,
                                              color: Colors.grey[400],
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: index == 0 
                                          ? Colors.grey[600] 
                                          : Colors.black,
                                    ),
                                    controller: TextEditingController(
                                      text: playerNames[index],
                                    ),
                                    onChanged: (value) {
                                      // Solo permitir cambios si no es el usuario (index 0)
                                      if (index != 0) {
                                        setState(() {
                                          playerNames[index] = value.isEmpty 
                                              ? 'Jugador ${index + 1}' 
                                              : value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            // Selector CPU/Humano (Jugador 1 siempre es humano)
                            GestureDetector(
                              onTap: index == 0 ? null : () { // Bloquear tap para Jugador 1
                                setState(() {
                                  isHuman[index] = !isHuman[index];
                                  if (!isHuman[index]) {
                                    playerNames[index] = 'CPU ${index + 1}';
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 6
                                ),
                                decoration: BoxDecoration(
                                  color: index == 0 
                                      ? Colors.blue[50] // Color especial para Jugador 1
                                      : (isHuman[index] 
                                          ? Colors.green[100]
                                          : Colors.orange[100]),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: index == 0 
                                        ? Colors.blue[300]! // Borde especial para Jugador 1
                                        : (isHuman[index] 
                                            ? Colors.green
                                            : Colors.orange),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      index == 0 
                                          ? Icons.account_circle // Icono especial para Jugador 1
                                          : (isHuman[index] 
                                              ? Icons.person 
                                              : Icons.smart_toy),
                                      size: 20,
                                      color: index == 0 
                                          ? Colors.blue[700] // Color especial para Jugador 1
                                          : (isHuman[index] 
                                              ? Colors.green[700]
                                              : Colors.orange[700]),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      index == 0 
                                          ? 'TÚ' // Texto especial para Jugador 1
                                          : (isHuman[index] ? 'HUMANO' : 'CPU'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: index == 0 
                                            ? Colors.blue[700] // Color especial para Jugador 1
                                            : (isHuman[index] 
                                                ? Colors.green[700]
                                                : Colors.orange[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 10),
                            
                            // Selector de Color
                            GestureDetector(
                              onTap: () => _showColorPicker(index),
                              child: Container(
                                width: 45,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: availableColors[selectedColorIndices[index]],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.palette,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Botón Jugar
                Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: () async {
                      // Generar orden aleatorio de turnos
                      List<int> turnOrder = List.generate(numPlayers, (index) => index);
                      turnOrder.shuffle(); // Mezclar aleatoriamente
                      
                      // Guardar configuraciones
                      HiveService.savePlayerColors(selectedColorIndices);
                      HiveService.saveTurnOrder(turnOrder);
                      
                      // 🔇 DETENER MÚSICA DE FONDO ANTES DE ENTRAR AL JUEGO
                      await AudioService().stopBackgroundMusic();
                      print('🔇 Música de fondo detenida al iniciar partida');
                      
                      // Navegar al juego con la configuración
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ParchisBoard(
                            numPlayers: numPlayers,
                            playerNames: playerNames.take(numPlayers).toList(),
                            isHuman: isHuman.take(numPlayers).toList(),
                            playerColorIndices: selectedColorIndices.take(numPlayers).toList(),
                            turnOrder: turnOrder,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      '🎮 ¡JUGAR!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ParchisBoard extends StatefulWidget {
  final int numPlayers;
  final List<String> playerNames;
  final List<bool> isHuman;
  final List<int> playerColorIndices;
  final List<int> turnOrder;
  
  const ParchisBoard({
    super.key,
    this.numPlayers = 4,
    this.playerNames = const ['Rojo', 'Azul', 'Verde', 'Amarillo'],
    this.isHuman = const [true, true, true, true],
    this.playerColorIndices = const [0, 1, 2, 3],
    this.turnOrder = const [0, 1, 2, 3],
  });

  @override
  State<ParchisBoard> createState() => _ParchisBoardState();
}

class _ParchisBoardState extends State<ParchisBoard> with TickerProviderStateMixin, WidgetsBindingObserver {
  int diceValue = 1;
  Random random = Random();
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;
  
  // Lista de fichas del juego (4 colores)
  List<GamePiece> gamePieces = [];
  
  // Variables para control de turnos
  int currentPlayerIndex = 0; // Se inicializará con el primer jugador del turnOrder
  List<Color> playerColors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
  List<String> playerNames = ['Rojo', 'Azul', 'Verde', 'Amarillo'];
  List<String?> customPlayerNames = [null, null, null, null]; // Nombres personalizados (null = usar color)
  late List<int> turnOrder; // Orden de turnos aleatorio
  int currentTurnIndex = 0; // Índice actual en el turnOrder
  
  // 🎲 REGLAS CLÁSICAS DEL PARCHÍS
  int consecutiveSixes = 0; // Contador de seises consecutivos
  bool hasExtraTurn = false; // Indica si el jugador tiene turno extra por sacar 6
  int extraTurnsRemaining = 0; // NUEVO: Sistema de turnos extra acumulables
  bool isMoving = false; // Para bloquear el dado mientras se mueve una ficha
  GamePiece? jumpingPiece; // Para saber qué ficha está saltando
  String? pendingSpecialCellSound; // Para reproducir sonido de casilla especial al final de animación
  
  // Variables para mensajes jocosos
  String? lastMessage;
  Timer? _messageTimer;
  String currentMessage = ''; // Para mensajes de casillas especiales
  String? priorityMessage; // Para mensajes críticos (3 seises, eliminación, etc.)
  
  // 📬 NUEVO SISTEMA DE COLA DE MENSAJES
  late MessageQueue _messageQueue;
  
  // Ruta de movimiento en el tablero (secuencia de posiciones)
  List<Position> boardPath = [];

  // � SISTEMA DE CAMBIO DE JUGADAS
  List<int> remainingChanges = [3, 3, 3, 3]; // Cambios disponibles por jugador
  bool isDecisionTime = false; // ¿Está el jugador decidiendo si cambiar?
  int currentDiceResult = 0; // Resultado actual del dado
  Timer? _decisionTimer; // Timer para auto-continuar
  Timer? _cpuTimer; // Timer para movimientos del CPU
  
  // 🎵 CONTROL DE AUDIO PARA EVITAR DUPLICACIONES
  bool _isPlayingCollisionAudio = false; // Flag para evitar sonidos duplicados durante colisiones
  
  // 🧪 MODO DEBUG - PARA TESTING DE 3 SEISES
  // ✅ true = SIEMPRE SALE 6 (para probar regla de 3 seises)
  // ❌ false = ALEATORIO NORMAL (para juego real)
  bool debugMode = false; // ← CAMBIAR A false PARA MODO NORMAL
  int decisionCountdown = 3; // Countdown de 3 segundos

  // ⏰ SISTEMA DE TIMER PARA JUGADORES HUMANOS
  Timer? _playerTimer; // Timer de 10 segundos por turno
  int timerCountdown = 10; // Contador de timer (10 segundos)
  bool isTimerFlashing = false; // Para el parpadeo visual a los 5s
  List<int> autoLaunchCount = [0, 0, 0, 0]; // Contador de lanzamientos automáticos por jugador
  static const int maxAutoLaunches = 3; // Máximo de lanzamientos automáticos antes de eliminación

  // 🏆 SISTEMA DE FINALIZACIÓN DEL JUEGO
  List<bool> playerFinished = [false, false, false, false]; // Jugadores que terminaron
  List<int> finishOrder = []; // Orden de llegada a la meta
  bool gameEnded = false; // Si el juego terminó
  
  // 💀 SISTEMA DE ELIMINACIÓN
  List<bool> playerEliminated = [false, false, false, false]; // Jugadores eliminados

  // 🎵 SISTEMA DE MÚSICA DRAMÁTICA
  bool isDramaticMusicPlaying = false; // Control de música dramática

  // ⏸️ SISTEMA DE PAUSA
  bool isPaused = false; // Estado de pausa
  bool wasAutoPaused = false; // Para distinguir pausa manual vs automática

  // �👤 SISTEMA DE PERFILES DE JUGADORES
  
  // Obtener nombre del jugador con formato correcto
  String _getPlayerDisplayName(int playerIndex) {
    if (playerIndex == 0 && widget.isHuman[0]) {
      // Si es el jugador humano, usar el nombre del usuario actual
      return customPlayerNames[0] ?? playerNames[0];
    } else {
      return customPlayerNames[playerIndex] ?? 'CPU $playerIndex';
    }
  }
  
  // Obtener color del jugador
  Color _getPlayerColor(int playerIndex) {
    return playerColors[playerIndex];
  }
  
  // Obtener ícono del estado del jugador
  String _getPlayerStatusIcon(int playerIndex) {
    if (playerIndex == currentPlayerIndex) {
      if (hasExtraTurn) return '🎲'; // Turno extra
      return '⭐'; // Turno actual
    }
    return '💤'; // Esperando
  }
  
  // Mostrar modal de detalles del jugador
  void _showPlayerProfile(int playerIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getPlayerColor(playerIndex),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getPlayerDisplayName(playerIndex),
                style: TextStyle(
                  color: _getPlayerColor(playerIndex),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileRow('🎨 Color:', _getColorName(_getPlayerColor(playerIndex))),
              _buildProfileRow('🤖 Tipo:', widget.isHuman[playerIndex] ? 'Humano' : 'CPU'),
              _buildProfileRow('🎯 Estado:', playerIndex == currentPlayerIndex ? 'En turno' : 'Esperando'),
              if (playerIndex == currentPlayerIndex && hasExtraTurn)
                _buildProfileRow('✨ Extra:', 'Turno extra activo'),
              if (playerIndex == currentPlayerIndex && consecutiveSixes > 0)
                _buildProfileRow('🎲 Seises:', '$consecutiveSixes consecutivos'),
              const SizedBox(height: 10),
              const Text(
                '📊 Futuras estadísticas se mostrarán aquí',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar perfil
                _showEditNicknameDialog(playerIndex); // Abrir editor de apodo
              },
              child: const Text(
                '✏️ Cambiar Apodo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // 🏷️ EDITOR DE APODOS DINÁMICO
  void _showEditNicknameDialog(int playerIndex) {
    String currentName = _getPlayerName(playerIndex);
    String newName = currentName;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple.shade50,
          title: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getPlayerColor(playerIndex),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Cambiar Apodo',
                style: TextStyle(
                  color: _getPlayerColor(playerIndex),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo apodo para ${_getColorName(_getPlayerColor(playerIndex))}:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: currentName),
                decoration: InputDecoration(
                  hintText: 'Escribe el nuevo apodo...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                maxLength: 15,
                onChanged: (value) {
                  newName = value.trim();
                },
                onSubmitted: (value) {
                  _updatePlayerNickname(playerIndex, value.trim());
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              Text(
                '💡 Consejo: Máximo 15 caracteres',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _updatePlayerNickname(playerIndex, newName);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getPlayerColor(playerIndex),
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // 💾 ACTUALIZAR APODO DE JUGADOR
  void _updatePlayerNickname(int playerIndex, String newName) {
    setState(() {
      if (newName.isEmpty) {
        // Si está vacío, usar el nombre por defecto (color)
        customPlayerNames[playerIndex] = null;
      } else {
        // Actualizar con el nuevo apodo
        customPlayerNames[playerIndex] = newName;
      }
    });
    
    // Mostrar confirmación
    _showMessage(
      "✅ Apodo actualizado: ${_getPlayerName(playerIndex)}",
      priority: MessagePriority.normal,
      durationSeconds: 2
    );
    
    // 🎵 Sonido de confirmación
    AudioService().playPieceUp();
  }

  // Widget auxiliar para filas del perfil
  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // 🔄 SISTEMA DE CAMBIO DE JUGADAS
  
  // Iniciar período de decisión después del lanzamiento
  void _startDecisionPeriod(int diceResult) {
    if (remainingChanges[currentPlayerIndex] <= 0) {
      // No tiene cambios disponibles, continuar normalmente
      _continueWithDiceResult(diceResult);
      return;
    }

    setState(() {
      isDecisionTime = true;
      currentDiceResult = diceResult;
      decisionCountdown = 3; // Cambiado de 5 a 3 segundos
    });

    // Si es CPU, tomar decisión automática
    if (!widget.isHuman[currentPlayerIndex]) {
      _cpuMakeChangeDecision();
      return;
    }

    // Para humanos: countdown de 3 segundos
    _startDecisionCountdown();
  }

  // Countdown para decisión del humano
  void _startDecisionCountdown() {
    _decisionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        decisionCountdown--;
      });
      
      // 🎵 Sonido de timer solo en momentos clave (no cada segundo)
      /*if (decisionCountdown == 1) {
        AudioService().playTimer(); // Solo sonido en el último segundo
      }*/

      if (decisionCountdown <= 0) {
        timer.cancel();
        _continueWithCurrentResult(); // Auto-continuar si no decide
      }
    });
  }

  // CPU decide inteligentemente si cambiar
  void _cpuMakeChangeDecision() {
    Timer(const Duration(milliseconds: 1500), () {
      bool shouldChange = _cpuShouldChange(currentDiceResult);
      
      if (shouldChange && remainingChanges[currentPlayerIndex] > 0) {
        _changeCurrentDiceResult();
      } else {
        _continueWithCurrentResult();
      }
    });
  }

  // Lógica inteligente del CPU para decidir si cambiar
  bool _cpuShouldChange(int diceResult) {
    // CPU es más probable que cambie números bajos (1-2)
    if (diceResult <= 2 && remainingChanges[currentPlayerIndex] > 1) return true;
    
    // Si tiene pocos cambios, ser más selectivo
    if (remainingChanges[currentPlayerIndex] == 1) {
      return diceResult == 1; // Solo cambiar si sale 1
    }
    
    // Cambiar si el resultado no es favorable (20% probabilidad para 3-5)
    if (diceResult >= 3 && diceResult <= 5) {
      return Random().nextBool() && Random().nextBool(); // 25% chance
    }
    
    return false; // Nunca cambiar 6
  }

  // Jugador humano decide cambiar
  void _playerChooseChange() {
    if (remainingChanges[currentPlayerIndex] > 0) {
      _changeCurrentDiceResult();
    }
  }

  // Ejecutar cambio de dado
  void _changeCurrentDiceResult() {
    _decisionTimer?.cancel();
    
    setState(() {
      remainingChanges[currentPlayerIndex]--;
      isDecisionTime = false;
      _showMessage("🔄 ¡Cambiando jugada! (${remainingChanges[currentPlayerIndex]} cambios restantes)",
          priority: MessagePriority.normal, durationSeconds: 2);
    });

    // 🎯 GENERAR NUEVO RESULTADO ANTES de la animación
    int newFinalResult = debugMode ? 6 : Random().nextInt(6) + 1;

    // Nuevo lanzamiento de dado
    _playDiceSound();
    _animationController.reset();
    _animationController.forward();
    
    Timer? newDiceTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        currentDiceResult = Random().nextInt(6) + 1; // Animación aleatoria
      });
    });

    // ⏱️ SINCRONIZAR CON DURACIÓN DEL SONIDO DICE.MP3 + 1.5s adicionales para coordinación perfecta
    Timer(const Duration(milliseconds: 2500), () { // Aumentado de 1000ms a 2500ms (+ 1.5s)
      // ⏸️ VERIFICAR PAUSA ANTES DE CONTINUAR
      if (isPaused) return;
      
      newDiceTimer.cancel();
      
      setState(() {
        currentDiceResult = newFinalResult; // Asignar resultado final SIN cambio brusco
        _showMessage("🎲 Nuevo resultado: $newFinalResult",
            priority: MessagePriority.normal, durationSeconds: 2);
      });

      Timer(const Duration(milliseconds: 400), () { // Reducido delay para movimiento más rápido
        // ⏸️ VERIFICAR PAUSA ANTES DE CONTINUAR
        if (isPaused) return;
        
        setState(() {
          lastMessage = null;
        });
        _continueWithDiceResult(newFinalResult); // Usar el resultado final correcto
      });
    });
  }

  // Continuar con resultado actual (sin cambio)
  void _continueWithCurrentResult() {
    _decisionTimer?.cancel();
    setState(() {
      isDecisionTime = false;
    });
    _continueWithDiceResult(currentDiceResult);
  }

void _continueWithDiceResult(int finalResult) {
  // ⏸️ VERIFICAR SI EL JUEGO ESTÁ PAUSADO ANTES DE CONTINUAR
  if (isPaused) return;
  
  setState(() {
    diceValue = finalResult;
    isMoving = true; 
  });
  
  // 🚨 VERIFICAR REGLA DE 3 SEISES ANTES DE MOVER LA FICHA
  if (finalResult == 6) {
    consecutiveSixes++;
    
    // ¡TERCER 6 CONSECUTIVO! - PENALIZACIÓN INMEDIATA
    if (consecutiveSixes >= 3) {
      print("🚨 DEBUG: 3 seises detectados! Player: $currentPlayerIndex"); // Debug
      
      setState(() {
        consecutiveSixes = 0;
        hasExtraTurn = false;
        extraTurnsRemaining = 0; // Resetear turnos extra acumulados
        isMoving = false;
        
        // ENVIAR FICHA A LA SALIDA INMEDIATAMENTE
        gamePieces[currentPlayerIndex].position = const Position(9, 0);
      });
      
      // Mensaje crítico
      _showMessage("¡3 seises consecutivos! ¡${_getPlayerName(currentPlayerIndex)} vuelve a la salida! 😱💥",
          priority: MessagePriority.critical, durationSeconds: 4);
      
      // 🎵 Sonido de penalización
      AudioService().playLoseTurn();
      
      // Cambiar turno después del mensaje
      Timer(const Duration(milliseconds: 2500), () {
        // ⏸️ VERIFICAR PAUSA ANTES DE CONTINUAR
        if (isPaused) return;
        
        _nextActivePlayer();
        
        // Continuar con el siguiente jugador
        Timer(const Duration(milliseconds: 500), () {
          // ⏸️ VERIFICAR PAUSA ANTES DE CONTINUAR
          if (isPaused) return;
          
          if (_isCurrentPlayerCPU() && !isMoving) {
            _rollDice();
          } else if (widget.isHuman[currentPlayerIndex] && !isMoving) {
            _startPlayerTimer();
          }
        });
      });
      return; // ¡CRÍTICO! NO EJECUTAR EL MOVIMIENTO
    } else {
      // ✅ AGREGAR UN TURNO EXTRA POR SACAR 6 (no es el tercero)
      extraTurnsRemaining++;
      print("🎲 DEBUG: Dado 6 agregó turno extra. Total: $extraTurnsRemaining");
    }
  } else {
    // Si no es 6, resetear contador
    consecutiveSixes = 0;
  }
  
  // CONTINUAR CON MOVIMIENTO NORMAL
  Timer(const Duration(milliseconds: 300), () {
    Timer(const Duration(milliseconds: 100), () {
      bool hasThreats = _checkAndShowThreatMessage(finalResult);
      
      if (hasThreats) {
        Timer(const Duration(milliseconds: 1200), () {
          setState(() {
            lastMessage = null;
          });
          
          Timer(const Duration(milliseconds: 200), () {
            _moveCurrentPlayerPiece(finalResult);
          });
        });
      } else {
        Timer(const Duration(milliseconds: 200), () {
          _moveCurrentPlayerPiece(finalResult);
        });
      }
    });
  });
}


  @override
  void initState() {
    super.initState();
    
    // 📱 OBSERVER PARA CICLO DE VIDA DE LA APP (pausa automática)
    WidgetsBinding.instance.addObserver(this);
    
    // 📱 ACTIVAR WAKELOCK - MANTENER PANTALLA ENCENDIDA
    _enableWakelock();
    
    // 🔇 ASEGURAR QUE LA MÚSICA DE FONDO ESTÉ DETENIDA DURANTE EL JUEGO
    _stopBackgroundMusicInGame();
    
    // Configurar orden de turnos y colores
    turnOrder = widget.turnOrder;
    currentTurnIndex = 0;
    currentPlayerIndex = turnOrder[currentTurnIndex]; // Empezar con el primer jugador del orden aleatorio
    
    // Configurar colores personalizados de jugadores
    for (int i = 0; i < widget.numPlayers; i++) {
      customPlayerNames[i] = widget.playerNames[i];
      // Actualizar colores según la selección del usuario
      if (i < widget.playerColorIndices.length) {
        playerColors[i] = [Colors.red, Colors.blue, Colors.green, Colors.yellow][widget.playerColorIndices[i]];
      }
    }
    
    // 🎮 AUTO-INICIAR SI EL PRIMER JUGADOR ES CPU / ⏰ TIMER SI ES HUMANO
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 1000), () {
        if (_isCurrentPlayerCPU() && !isMoving) {
          _rollDice();
        } else if (widget.isHuman[currentPlayerIndex] && !isMoving) {
          // Iniciar timer para el primer jugador si es humano
          _startPlayerTimer();
        }
      });
    });
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi * 3, // Gira 3 veces completas
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Controlador para la animación de salto
    _jumpController = AnimationController(
      duration: const Duration(milliseconds: 400), // Aumentado de 250ms a 400ms
      vsync: this,
    );
    
    _jumpAnimation = Tween<double>(
      begin: 0.0,
      end: -8.0, // Levanta 8 pixels hacia arriba
    ).animate(CurvedAnimation(
      parent: _jumpController,
      curve: Curves.easeInOut,
    ));

    // Inicializar las fichas en la casilla de salida (9,0)
    _initializeGamePieces();
    
    // Crear la ruta del tablero
    _initializeBoardPath();
    
    // 📬 INICIALIZAR SISTEMA DE COLA DE MENSAJES
    _messageQueue = MessageQueue();
    _messageQueue.onDisplayMessage = (MessageData message) {
      setState(() {
        // Asignar a la variable apropiada según prioridad
        switch (message.priority) {
          case MessagePriority.critical:
            priorityMessage = message.text;
            break;
          case MessagePriority.high:
          case MessagePriority.normal:
            lastMessage = message.text;
            break;
          case MessagePriority.special:
            currentMessage = message.text;
            break;
        }
      });
    };
    
    _messageQueue.onClearMessage = () {
      setState(() {
        lastMessage = null;
        currentMessage = '';
        priorityMessage = null;
      });
    };

    // 🎵 ASEGURAR QUE NO HAY MÚSICA DRAMÁTICA AL INICIO
    isDramaticMusicPlaying = false;

    // 📱 VIBRACIÓN INICIAL SI EL PRIMER JUGADOR ES HUMANO
    Timer(const Duration(milliseconds: 1000), () {
      if (widget.isHuman[currentPlayerIndex] && !isMoving) {
        // Vibración de bienvenida para el primer jugador humano
        HapticFeedback.heavyImpact();
        Timer(const Duration(milliseconds: 150), () {
          HapticFeedback.lightImpact();
        });
        Timer(const Duration(milliseconds: 300), () {
          HapticFeedback.lightImpact();
        });
      }
    });
  }

  void _initializeGamePieces() {
    const salidaPosition = Position(9, 0);
    gamePieces = [];
    
    // Solo crear fichas para los jugadores activos
    for (int i = 0; i < widget.numPlayers; i++) {
      gamePieces.add(
        GamePiece(
          id: '${i + 1}', 
          color: playerColors[i], 
          position: salidaPosition
        )
      );
    }
  }

  void _initializeBoardPath() {
    // Crear la secuencia de movimiento COMPLETA incluyendo casillas especiales
    // Basado en el orden exacto del tablero real
    boardPath = [
      // Fila 9: SALIDA (posición de inicio no está en el path), luego números 1-9
      Position(9, 1), Position(9, 2), Position(9, 3), Position(9, 4), 
      Position(9, 5), Position(9, 6), Position(9, 7), Position(9, 8), Position(9, 9),
      
      // Fila 8: números y casillas especiales en orden
      Position(8, 9), Position(8, 8), Position(8, 7), Position(8, 6), Position(8, 5), 
      Position(8, 4), Position(8, 3), Position(8, 2), Position(8, 1), Position(8, 0),
      
      // Fila 7: números y casillas especiales en orden
      Position(7, 0), Position(7, 1), Position(7, 2), Position(7, 3), Position(7, 4), 
      Position(7, 5), Position(7, 6), Position(7, 7), Position(7, 8), Position(7, 9),
      
      // Fila 6: números y casillas especiales en orden
      Position(6, 9), Position(6, 8), Position(6, 7), Position(6, 6), Position(6, 5), 
      Position(6, 4), Position(6, 3), Position(6, 2), Position(6, 1), Position(6, 0),
      
      // Fila 5: números y casillas especiales en orden
      Position(5, 0), Position(5, 1), Position(5, 2), Position(5, 3), Position(5, 4), 
      Position(5, 5), Position(5, 6), Position(5, 7), Position(5, 8), Position(5, 9),
      
      // Fila 4: números y casillas especiales en orden
      Position(4, 9), Position(4, 8), Position(4, 7), Position(4, 6), Position(4, 5), 
      Position(4, 4), Position(4, 3), Position(4, 2), Position(4, 1), Position(4, 0),
      
      // Fila 3: números y casillas especiales en orden
      Position(3, 0), Position(3, 1), Position(3, 2), Position(3, 3), Position(3, 4), 
      Position(3, 5), Position(3, 6), Position(3, 7), Position(3, 8), Position(3, 9),
      
      // Fila 2: números y casillas especiales en orden
      Position(2, 9), Position(2, 8), Position(2, 7), Position(2, 6), Position(2, 5), 
      Position(2, 4), Position(2, 3), Position(2, 2), Position(2, 1), Position(2, 0),
      
      // Fila 1: números y casillas especiales en orden
      Position(1, 0), Position(1, 1), Position(1, 2), Position(1, 3), Position(1, 4), 
      Position(1, 5), Position(1, 6), Position(1, 7), Position(1, 8), Position(1, 9),
      
      // Fila 0: números y casillas especiales hasta META
      Position(0, 9), Position(0, 8), Position(0, 7), Position(0, 6), Position(0, 5), 
      Position(0, 4), Position(0, 3), Position(0, 2), Position(0, 1), Position(0, 0), // META
    ];
  }

  // ¡FUNCIONES DE SONIDO! 🎵🎲
  void _playDiceSound() {
    // 🎲 Reproducir sonido del dado
    AudioService().playDiceRoll();
    
    // Vibración táctil para simular el dado rodando
    HapticFeedback.heavyImpact();
    
    // Secuencia de vibraciones cortas para simular el dado rebotando
    Timer(const Duration(milliseconds: 100), () => HapticFeedback.mediumImpact());
    Timer(const Duration(milliseconds: 200), () => HapticFeedback.lightImpact());
    Timer(const Duration(milliseconds: 300), () => HapticFeedback.mediumImpact());
    Timer(const Duration(milliseconds: 400), () => HapticFeedback.lightImpact());
    Timer(const Duration(milliseconds: 600), () => HapticFeedback.heavyImpact()); // Final del dado
  }
  

  
  void _playSpecialCellSound(String cellType) {
    // 🎵 NO REPRODUCIR SONIDOS DURANTE COLISIONES PARA EVITAR DUPLICACIÓN
    if (_isPlayingCollisionAudio) {
      // Solo vibración durante colisiones, sin audio
      HapticFeedback.lightImpact();
      return;
    }
    
    switch (cellType) {
      case 'LANCE\nDE\nNUEVO':
        // 🎯 Sonido de nuevo turno
        AudioService().playNewTurn();
        HapticFeedback.lightImpact();
        Timer(const Duration(milliseconds: 100), () => HapticFeedback.lightImpact());
        Timer(const Duration(milliseconds: 200), () => HapticFeedback.mediumImpact());
        break;
      case 'VUELVE\nA LA\nSALIDA':
        // � SONIDO MOVIDO: Se reproducirá cuando la ficha llegue a SALIDA visualmente
        // Solo vibración inmediata para feedback de casilla especial
        HapticFeedback.heavyImpact();
        Timer(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
        Timer(const Duration(milliseconds: 400), () => HapticFeedback.heavyImpact());
        break;
      case '1 TURNO\nSIN\nJUGAR':
        // 😴 Sonido de perder turno
        AudioService().playLoseTurn();
        HapticFeedback.mediumImpact();
        Timer(const Duration(milliseconds: 300), () => HapticFeedback.lightImpact());
        break;
      default:
        // 📈 SONIDO MOVIDO: Se reproducirá cuando la ficha llegue a la nueva posición
        // Solo vibración inmediata para feedback de casilla especial
        HapticFeedback.mediumImpact();
        Timer(const Duration(milliseconds: 150), () => HapticFeedback.mediumImpact());
    }
  }

  // � FUNCIÓN AUXILIAR: Determinar si una casilla especial causa movimiento inmediato
  bool _causesMovement(String specialText) {
    switch (specialText) {
      case 'SUBE\nAL\n63':
      case 'SUBE\nAL\n70':
      case 'VUELVE\nA LA\nSALIDA':
      case 'BAJA\nAL\n24':
      case 'BAJA\nAL\n30':
      case 'BAJA\nAL\n40':
      case 'BAJA\nAL\n50':
        return true; // Estas casillas causan teletransporte/movimiento
      default:
        return false; // Otras casillas no causan movimiento inmediato
    }
  }

  // �🎵 NUEVA FUNCIÓN: Reproducir sonido de casilla especial después del movimiento
  void _playSpecialCellSoundAfterMovement(Position position) {
    // Usar el sonido almacenado en lugar de detectar la casilla actual
    if (pendingSpecialCellSound != null) {
      String cellType = pendingSpecialCellSound!;
      
      switch (cellType) {
        case 'SUBE\nAL\n63':
        case 'SUBE\nAL\n70':
          // 🚀 Sonido de subir para casillas que te llevan hacia arriba
          AudioService().playPieceUp();
          break;
        case 'VUELVE\nA LA\nSALIDA':
          // 📉 Sonido de bajar cuando llegas a la SALIDA
          AudioService().playPieceDown();
          break;
        case 'BAJA\nAL\n24':
        case 'BAJA\nAL\n30':
        case 'BAJA\nAL\n40':
        case 'BAJA\nAL\n50':
          // ⬇️ Sonido de bajar para casillas que te llevan hacia abajo
          AudioService().playPieceDown();
          break;
        default:
          // No reproducir sonido para otras casillas
          break;
      }
      
      // Limpiar el sonido pendiente
      pendingSpecialCellSound = null;
    }
  }

  // 📬 GESTIÓN UNIFICADA DE MENSAJES
  // 📬 NUEVA FUNCIÓN DE MENSAJES CON COLA - EVITA CANCELACIONES PREMATURAS
  void _showMessage(String message, {MessagePriority priority = MessagePriority.normal, int durationSeconds = 3}) {
    // 🎯 USAR SISTEMA DE COLA PARA EVITAR QUE SE CUELGUEN LOS MENSAJES
    _messageQueue.addMessage(message, priority, durationSeconds);
  }

  @override
  void dispose() {
    // � REMOVER OBSERVER DEL CICLO DE VIDA DE LA APP
    WidgetsBinding.instance.removeObserver(this);
    
    // �🔐 DESACTIVAR WAKELOCK AL SALIR DEL JUEGO
    _disableWakelock();
    
    // 🛑 CANCELAR TODOS LOS TIMERS ACTIVOS
    _timer?.cancel();
    _messageTimer?.cancel();
    _decisionTimer?.cancel();
    _playerTimer?.cancel();
    _cpuTimer?.cancel();
    
    // 🔇 DETENER TODOS LOS AUDIOS DEL JUEGO
    try {
      AudioService().stopAllSounds(); // Detener todos los sonidos activos
    } catch (e) {
      print('Error al detener audio: $e');
    }
    
    // 🧹 LIMPIAR CONTROLADORES DE ANIMACIÓN
    _animationController.dispose();
    _jumpController.dispose();
    
    // 📬 LIMPIAR SISTEMA DE COLA DE MENSAJES
    _messageQueue.clear();
    
    // 🧹 LIMPIAR VARIABLES DE ESTADO (SIN setState PARA EVITAR ERRORES)
    isMoving = false;
    gameEnded = true; // Marcar juego como terminado
    lastMessage = null;
    currentMessage = '';
    priorityMessage = null;
    
    super.dispose();
  }

  // ⏸️ SISTEMA DE PAUSA AUTOMÁTICA Y MANUAL

  // 📱 DETECTAR CAMBIOS EN EL CICLO DE VIDA DE LA APP
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App se fue a segundo plano - PAUSA AUTOMÁTICA
        if (!isPaused && !gameEnded) {
          _pauseGameAutomatically();
        }
        break;
      case AppLifecycleState.resumed:
        // App volvió al primer plano - REANUDAR SI FUE PAUSA AUTOMÁTICA
        if (wasAutoPaused && isPaused) {
          _resumeGameAutomatically();
        }
        break;
      case AppLifecycleState.detached:
        // App se está cerrando - no hacer nada especial
        break;
      case AppLifecycleState.hidden:
        // App está oculta - tratarlo como pausa
        if (!isPaused && !gameEnded) {
          _pauseGameAutomatically();
        }
        break;
    }
  }

  // 🎯 PAUSA MANUAL (botón)
  void _togglePauseManually() {
    if (gameEnded) return; // No pausar si el juego terminó
    
    setState(() {
      isPaused = !isPaused;
      wasAutoPaused = false; // Es pausa manual
    });
    
    if (isPaused) {
      _pauseGameSystems();
      _showPauseDialog(); // Solo mostrar diálogo en pausa manual
    } else {
      _resumeGameSystems();
    }
  }

  // 🔄 PAUSA AUTOMÁTICA (cuando sales de la app)
  void _pauseGameAutomatically() {
    setState(() {
      isPaused = true;
      wasAutoPaused = true; // Marcar como pausa automática
    });
    
    _pauseGameSystems(); // Pausar todos los sistemas
    
    print('⏸️ Juego pausado automáticamente (app en segundo plano)');
  }

  // ▶️ REANUDACIÓN AUTOMÁTICA (cuando vuelves a la app)
  void _resumeGameAutomatically() {
    setState(() {
      isPaused = false;
      wasAutoPaused = false;
    });
    
    _resumeGameSystems(); // Reanudar sistemas
    
    print('▶️ Juego reanudado automáticamente (app en primer plano)');
  }

  // ⏸️ PAUSAR TODOS LOS SISTEMAS DEL JUEGO
  void _pauseGameSystems() {
    // Pausar timers
    _playerTimer?.cancel();
    _cpuTimer?.cancel();
    _decisionTimer?.cancel();
    _timer?.cancel();
    _messageTimer?.cancel();
    
    // Pausar animaciones
    _animationController.stop();
    _jumpController.stop();
    
    // Pausar audio
    AudioService().pauseBackgroundMusic();
    
    print('⏸️ Todos los sistemas del juego pausados');
  }

  // ▶️ REANUDAR TODOS LOS SISTEMAS DEL JUEGO
  void _resumeGameSystems() {
    // Reanudar audio
    AudioService().resumeBackgroundMusic();
    
    // Reanudar timers según el estado del juego
    if (!gameEnded) {
      if (widget.isHuman[currentPlayerIndex] && !isMoving) {
        _startPlayerTimer(); // Reiniciar timer si es humano
      } else if (_isCurrentPlayerCPU() && !isMoving) {
        _cpuTimer = Timer(const Duration(milliseconds: 1000), () => _rollDice());
      }
    }
    
    print('▶️ Todos los sistemas del juego reanudados');
  }

  // 📋 DIÁLOGO DE PAUSA (solo para pausa manual)
  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.pause_circle, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('⏸️ JUEGO PAUSADO', style: TextStyle(color: Colors.orange, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('El juego está pausado. ¿Qué quieres hacer?', 
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            // Estado actual del juego
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text('🎮 Turno actual: ${_getPlayerDisplayName(currentPlayerIndex)}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('🎲 Último dado: $diceValue'),
                  if (extraTurnsRemaining > 0)
                    Text('✨ Turnos extra: $extraTurnsRemaining'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showExitDialog(); // Usar función existente
                  },
                  child: Text('🏠 Salir al Menú'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _togglePauseManually(); // Reanudar
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('▶️ Continuar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📱 WAKELOCK - MANTENER PANTALLA ACTIVA

  // 🔐 ACTIVAR PANTALLA SIEMPRE ENCENDIDA
  void _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      print('✅ Wakelock activado - Pantalla permanecerá encendida');
    } catch (e) {
      print('❌ Error al activar wakelock: $e');
    }
  }

  // 🔓 DESACTIVAR PANTALLA SIEMPRE ENCENDIDA
  void _disableWakelock() async {
    try {
      await WakelockPlus.disable();
      print('✅ Wakelock desactivado - Pantalla volverá a comportamiento normal');
    } catch (e) {
      print('❌ Error al desactivar wakelock: $e');
    }
  }

  // 🔇 DETENER MÚSICA DE FONDO EN EL JUEGO
  void _stopBackgroundMusicInGame() async {
    try {
      await AudioService().stopBackgroundMusic();
      print('🔇 Música de fondo detenida durante el juego');
    } catch (e) {
      print('❌ Error al detener música de fondo en el juego: $e');
    }
  }

  // 🎵 REVISAR Y ACTIVAR MÚSICA DRAMÁTICA
  void _checkAndActivateDramaticMusic() async {
    // Verificar si hay fichas en las últimas 5 casillas antes de META
    bool hasPiecesInDramaticZone = false;
    
    for (int i = 0; i < gamePieces.length; i++) {
      GamePiece piece = gamePieces[i];
      
      // Saltear fichas eliminadas o en posiciones especiales
      if (piece.position.row == -1 && piece.position.col == -1) continue;
      if (piece.position.row == 9 && piece.position.col == 0) continue; // En salida
      if (piece.position.row == 0 && piece.position.col == 0) continue; // Ya en META
      
      // Encontrar el índice de la ficha en boardPath
      int currentPathIndex = -1;
      for (int j = 0; j < boardPath.length; j++) {
        if (boardPath[j].row == piece.position.row && 
            boardPath[j].col == piece.position.col) {
          currentPathIndex = j;
          break;
        }
      }
      
      // ✅ NUEVA LÓGICA: Verificar si está en las últimas 5 casillas
      // META está en último índice, entonces últimas 5 son: metaIndex-4 hasta metaIndex
      int metaIndex = boardPath.length - 1; // Último índice (META)
      int dramaticZoneStart = metaIndex - 4; // 5 casillas antes
      
      if (currentPathIndex >= dramaticZoneStart && currentPathIndex <= metaIndex) {
        hasPiecesInDramaticZone = true;
        print("🎭 DEBUG: Ficha en zona dramática - Índice: $currentPathIndex, Zona: $dramaticZoneStart-$metaIndex");
        break;
      }
    }

    // Activar música dramática si hay fichas en zona y no está ya sonando
    if (hasPiecesInDramaticZone && !isDramaticMusicPlaying) {
      try {
        await AudioService().playBackgroundMusic('Dramatic.mp3', volumeMultiplier: 0.5);
        isDramaticMusicPlaying = true;
        print('🎭 Música dramática activada - Fichas en últimas 5 casillas (volumen reducido)');
      } catch (e) {
        print('❌ Error al activar música dramática: $e');
      }
    }
    // Desactivar música dramática si no hay fichas en zona y está sonando
    else if (!hasPiecesInDramaticZone && isDramaticMusicPlaying) {
      try {
        await AudioService().stopBackgroundMusic();
        isDramaticMusicPlaying = false;
        print('🔇 Música dramática desactivada - No hay fichas en zona final');
      } catch (e) {
        print('❌ Error al desactivar música dramática: $e');
      }
    }
  }

  // ⏰ SISTEMA DE TIMER PARA JUGADORES HUMANOS
  
  void _startPlayerTimer() {
    // Solo para jugadores humanos
    if (!widget.isHuman[currentPlayerIndex] || isMoving || isPaused) return;
    
    // 📱 VIBRACIÓN PARA ALERTAR TURNO HUMANO
    HapticFeedback.mediumImpact();
    Timer(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
    Timer(const Duration(milliseconds: 400), () {
      HapticFeedback.mediumImpact();
    });
    
    setState(() {
      timerCountdown = 10;
      isTimerFlashing = false;
    });
    
    _playerTimer?.cancel(); // Cancelar timer anterior
    _playerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timerCountdown--;
        
        // Activar parpadeo a los 5 segundos
        if (timerCountdown <= 5) {
          isTimerFlashing = true;
        }
      });
      
      // 🎵 Sonido de urgencia a los 5 segundos
      if (timerCountdown == 5) {
        AudioService().playTimer();
      } else if (timerCountdown <= 3 && timerCountdown > 0) {
        AudioService().playTimer(); // Sonido cada segundo en los últimos 3
      }
      
      // ⏰ TIEMPO AGOTADO - LANZAMIENTO AUTOMÁTICO
      if (timerCountdown <= 0) {
        timer.cancel();
        _handlePlayerTimeout();
      }
    });
  }
  
  void _stopPlayerTimer() {
    _playerTimer?.cancel();
    setState(() {
      timerCountdown = 10;
      isTimerFlashing = false;
    });
  }
  
  void _handlePlayerTimeout() {
    autoLaunchCount[currentPlayerIndex]++;
    
    setState(() {
      lastMessage = "⏰ ¡Tiempo agotado! Lanzamiento automático (${autoLaunchCount[currentPlayerIndex]}/$maxAutoLaunches)";
      isTimerFlashing = false;
    });
    
    // 🎵 Sonido de timeout
    AudioService().playLoseTurn();
    
    // Verificar si debe ser eliminado
    if (autoLaunchCount[currentPlayerIndex] >= maxAutoLaunches) {
      _eliminatePlayer();
      return;
    }
    
    // Lanzar dado automáticamente
    Timer(const Duration(milliseconds: 1500), () {
      setState(() {
        lastMessage = null;
      });
      _autoRollDice();
    });
  }
  
  void _eliminatePlayer() {
    String playerName = _getPlayerDisplayName(currentPlayerIndex);
    
    setState(() {
      playerEliminated[currentPlayerIndex] = true; // Marcar como eliminado
      
      // 🗑️ REMOVER FICHA DEL TABLERO - DESAPARECE COMPLETAMENTE
      gamePieces[currentPlayerIndex].position = const Position(-1, -1); // Posición fuera del tablero
    });
    
    // Mensaje crítico de eliminación
    _showMessage("💀 ¡$playerName eliminado por inactividad! (3 timeouts)",
        priority: MessagePriority.critical, durationSeconds: 5);
    
    // 🎵 Sonido de eliminación
    AudioService().playLoseTurn();
    
    // Verificar si el juego debe terminar
    Timer(const Duration(milliseconds: 2000), () {
      _checkGameEnd();
      
      if (!gameEnded) {
        // Si el juego no terminó, continuar con el siguiente jugador
        setState(() {
          _nextActivePlayer();
        });
        
        // Auto-continuar si el siguiente es CPU
        Timer(const Duration(milliseconds: 500), () {
          if (_isCurrentPlayerCPU() && !isMoving) {
            _rollDice();
          } else if (widget.isHuman[currentPlayerIndex] && !isMoving) {
            _startPlayerTimer(); // Iniciar timer para el nuevo jugador humano
          }
        });
      }
    });
  }
  
  void _autoRollDice() {
    // Lanzamiento automático sin timer
    _playDiceSound();
    
    int finalResult = debugMode ? 6 : random.nextInt(6) + 1;
    
    _animationController.reset();
    _animationController.forward();
    
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        diceValue = random.nextInt(6) + 1;
      });
    });

    // ⏱️ SINCRONIZAR CON DURACIÓN DEL SONIDO DICE.MP3 + 1.5s adicionales para coordinación perfecta
    Timer(const Duration(milliseconds: 2500), () { // Aumentado de 1000ms a 2500ms (+ 1.5s)
      _timer?.cancel();
      setState(() {
        diceValue = finalResult;
        isMoving = true;
      });
      
      _continueWithDiceResult(finalResult);
    });
  }

  // 🏆 SISTEMA DE FINALIZACIÓN DEL JUEGO
  
  void _checkPlayerFinished(int playerIndex) {
    // Verificar si el jugador llegó a la META (posición 0,0)
    GamePiece playerPiece = gamePieces[playerIndex];
    
    if (playerPiece.position.row == 0 && playerPiece.position.col == 0 && !playerFinished[playerIndex]) {
      setState(() {
        playerFinished[playerIndex] = true;
        finishOrder.add(playerIndex);
      });
      
      String playerName = _getPlayerDisplayName(playerIndex);
      int position = finishOrder.length;
      
      String positionText = _getPositionText(position);
      
      // Mensaje de alta prioridad para victoria
      _showMessage("🏆 ¡$playerName llega en $positionText lugar! 🎉",
          priority: MessagePriority.high, durationSeconds: 4);
      
      // Sonido según la posición
      if (position == 1) {
        AudioService().playPieceUp(); // Sonido épico de victoria (usamos el sonido de subir)
      } else {
        AudioService().playNewTurn(); // Sonido de logro
      }
      
      // Verificar si el juego debe terminar
      Timer(const Duration(milliseconds: 2000), () {
        _checkGameEnd();
      });
    }
  }
  
  String _getPositionText(int position) {
    switch (position) {
      case 1: return "1er";
      case 2: return "2do";
      case 3: return "3er";
      case 4: return "4to";
      default: return "${position}to";
    }
  }
  
  void _checkGameEnd() {
    if (gameEnded) return;
    
    // Contar jugadores activos (no eliminados y no terminados)
    int activePlayersCount = 0;
    for (int i = 0; i < widget.numPlayers; i++) {
      if (!playerFinished[i] && !playerEliminated[i]) {
        activePlayersCount++;
      }
    }
    
    // El juego termina cuando queda solo 1 jugador activo (o menos)
    if (activePlayersCount <= 1) {
      _endGame();
    }
  }
  
  void _endGame() {
    if (gameEnded) return;
    
    setState(() {
      gameEnded = true;
      isMoving = true; // Bloquear el dado
    });
    
    _stopPlayerTimer(); // Detener cualquier timer activo
    
    // � DESACTIVAR WAKELOCK AL TERMINAR EL JUEGO
    _disableWakelock();
    
    // �🔇 DETENER AUDIOS AL TERMINAR EL JUEGO
    try {
      AudioService().stopAllSounds();
    } catch (e) {
      print('Error al detener audio al terminar juego: $e');
    }
    
    // Agregar jugadores restantes al final del orden
    for (int i = 0; i < widget.numPlayers; i++) {
      if (!playerFinished[i] && !playerEliminated[i]) {
        finishOrder.add(i);
      }
    }
    
    // Agregar jugadores eliminados al final
    for (int i = 0; i < widget.numPlayers; i++) {
      if (playerEliminated[i] && !finishOrder.contains(i)) {
        finishOrder.add(i);
      }
    }
    
    // Mostrar pantalla de resultados
    Timer(const Duration(milliseconds: 1500), () {
      _showGameResults();
    });
  }
  
  void _showGameResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              SizedBox(width: 10),
              Text(
                '🏆 RESULTADOS FINALES',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...finishOrder.asMap().entries.map((entry) {
                  int position = entry.key + 1;
                  int playerIndex = entry.value;
                  bool isWinner = position == 1;
                  bool isEliminated = playerEliminated[playerIndex];
                  
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isWinner 
                          ? Colors.amber.withOpacity(0.2)
                          : isEliminated
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isWinner 
                            ? Colors.amber
                            : isEliminated
                                ? Colors.red
                                : Colors.grey,
                        width: isWinner ? 3 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Posición
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isWinner 
                                ? Colors.amber
                                : isEliminated
                                    ? Colors.red
                                    : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isEliminated ? '💀' : _getPositionText(position),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isWinner ? 16 : 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        
                        // Color del jugador
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _getPlayerColor(playerIndex),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        SizedBox(width: 15),
                        
                        // Nombre y status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEliminated ? '💀 ${_getPlayerDisplayName(playerIndex)}' : _getPlayerDisplayName(playerIndex),
                                style: TextStyle(
                                  fontSize: isWinner ? 18 : 16,
                                  fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
                                  color: isEliminated ? Colors.red[700] : Colors.black,
                                  decoration: isEliminated ? TextDecoration.lineThrough : null, // ← TACHADO
                                  decorationColor: isEliminated ? Colors.red[700] : null,
                                  decorationThickness: isEliminated ? 2.0 : null,
                                ),
                              ),
                              if (isEliminated)
                                Text(
                                  '⚠️ ELIMINADO POR INACTIVIDAD',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red[800],
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Ícono especial para el ganador
                        if (isWinner)
                          Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 32,
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar diálogo
                      _restartGame(); // Reiniciar juego
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '🔄 Jugar de Nuevo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop(); // Cerrar diálogo
                      Navigator.of(context).pop(); // Volver al menú principal
                      
                      // 🎵 REANUDAR MÚSICA DE FONDO AL VOLVER AL MENÚ
                      try {
                        await Future.delayed(const Duration(milliseconds: 500));
                        await AudioService().playBackgroundMusic('background.mp3');
                        print('🎵 Música de fondo reanudada al volver al menú');
                      } catch (e) {
                        print('❌ Error reanudando música de fondo: $e');
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '🏠 Menú Principal',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  void _restartGame() {
    setState(() {
      // Reiniciar variables de juego
      gameEnded = false;
      isMoving = false;
      currentPlayerIndex = 0;
      consecutiveSixes = 0;
      hasExtraTurn = false;
      lastMessage = null;
      
      // Reiniciar arrays
      playerFinished = [false, false, false, false];
      playerEliminated = [false, false, false, false];
      finishOrder.clear();
      autoLaunchCount = [0, 0, 0, 0];
      
      // Reiniciar fichas a la salida
      for (int i = 0; i < gamePieces.length; i++) {
        gamePieces[i].position = const Position(9, 0);
      }
    });
    
    // Iniciar el primer turno
    Timer(const Duration(milliseconds: 1000), () {
      if (_isCurrentPlayerCPU() && !isMoving) {
        _rollDice();
      } else if (widget.isHuman[currentPlayerIndex] && !isMoving) {
        _startPlayerTimer();
      }
    });
  }

  void _rollDice() {
    if (_timer != null && _timer!.isActive) return;
    if (isMoving) return; // No permitir lanzar dado mientras se mueve una ficha
    if (isPaused) return; // ⏸️ No permitir lanzar dado si el juego está pausado
    
    // ⏰ DETENER TIMER AL LANZAR DADO
    _stopPlayerTimer();
    
    // 🔄 RESETEAR CONTADOR DE TIMEOUTS (lanzamiento manual)
    autoLaunchCount[currentPlayerIndex] = 0;
    
    // 🤖 SISTEMA CPU INTELIGENTE - ¡ÉPICO!
    if (_isCurrentPlayerCPU()) {
      _executeCPUTurn();
      return;
    }
    
    // ¡SONIDO DEL DADO! 🎵
    _playDiceSound();
    
    // 🎯 GENERAR RESULTADO FINAL ANTES de la animación
    int finalDiceResult = debugMode ? 6 : random.nextInt(6) + 1;
    
    _animationController.reset();
    _animationController.forward();
    
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        diceValue = random.nextInt(6) + 1; // Animación aleatoria
      });
    });

    // ⏱️ SINCRONIZAR CON DURACIÓN DEL SONIDO DICE.MP3 + 1.5s adicionales para coordinación perfecta
    Timer(const Duration(milliseconds: 2500), () { // Aumentado de 1000ms a 2500ms (+ 1.5s)
      _timer?.cancel();
      setState(() {
        diceValue = finalDiceResult; // Asignar el resultado final SIN cambio brusco
        isMoving = true; // Bloquear el dado
      });
      
      // 🔄 NUEVO: Iniciar período de decisión para cambio de jugada
      _startDecisionPeriod(finalDiceResult);
    });
  }

  // Nueva función para verificar y mostrar mensaje de amenaza
  bool _checkAndShowThreatMessage(int steps) {
    GamePiece currentPiece = gamePieces[currentPlayerIndex];
    
    // Calcular la posición final después del movimiento
    int currentPathIndex = -1;
    
    if (currentPiece.position.row == 9 && currentPiece.position.col == 0) {
      currentPathIndex = -1;
    } else {
      for (int i = 0; i < boardPath.length; i++) {
        if (boardPath[i].row == currentPiece.position.row && 
            boardPath[i].col == currentPiece.position.col) {
          currentPathIndex = i;
          break;
        }
      }
    }
    
    int finalPathIndex = currentPathIndex + steps;
    if (finalPathIndex < boardPath.length) {
      Position finalPosition = boardPath[finalPathIndex];
      
      // Buscar si hay una ficha en la posición final
      for (int i = 0; i < gamePieces.length; i++) {
        if (i != currentPlayerIndex && 
            gamePieces[i].position.row == finalPosition.row &&
            gamePieces[i].position.col == finalPosition.col) {
          _showThreatMessage(currentPiece, gamePieces[i]);
          return true; // Hay amenaza
        }
      }
    }
    return false; // No hay amenaza
  }

  void _moveCurrentPlayerPiece(int steps) {
    // Obtener la ficha del jugador actual
    GamePiece currentPiece = gamePieces[currentPlayerIndex];
    
    // Encontrar la posición actual en la ruta
    int currentPathIndex = -1;
    
    // Si está en SALIDA, empezar desde el principio de la ruta
    if (currentPiece.position.row == 9 && currentPiece.position.col == 0) {
      currentPathIndex = -1; // Empezará desde 0
    } else {
      // Buscar la posición actual en la ruta
      for (int i = 0; i < boardPath.length; i++) {
        if (boardPath[i].row == currentPiece.position.row && 
            boardPath[i].col == currentPiece.position.col) {
          currentPathIndex = i;
          break;
        }
      }
    }
    
    // Animar el movimiento paso a paso
    _animateStepByStep(currentPiece, currentPathIndex, steps);
  }

  // 🤖 VERIFICA SI EL JUGADOR ACTUAL ES CPU
  bool _isCurrentPlayerCPU() {
    return !widget.isHuman[currentPlayerIndex];
  }

  // 🎭 SISTEMA CPU ÉPICO CON PERSONALIDAD
  void _executeCPUTurn() async {
    // ⏸️ VERIFICAR SI EL JUEGO ESTÁ PAUSADO ANTES DE EJECUTAR
    if (isPaused) return;
    
    setState(() {
      isMoving = true;
    });

    // 🎬 MOSTRAR MENSAJE DE "PENSANDO" DRAMÁTICO
    String thinkingMessage = _getEpicCPUThinkingMessage();
    if (mounted) {
      setState(() {
        lastMessage = thinkingMessage;
      });
    }

    // ⏱️ TIEMPO DE PENSAMIENTO DRAMÁTICO (2-4 segundos) - AUMENTADO PARA MEJOR EXPERIENCIA
    int thinkingTime = 2000 + random.nextInt(2000);
    await Future.delayed(Duration(milliseconds: thinkingTime));

    // 🎲 CPU LANZA EL DADO CON ESTILO
    if (mounted) {
      setState(() {
        lastMessage = "🎲 ¡Lanzando el dado mágico!";
      });
    }

    _playDiceSound();
    _animationController.reset();
    _animationController.forward();
    
    // Animación del dado
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        diceValue = random.nextInt(6) + 1;
      });
    });

    // ⏱️ SINCRONIZAR CON DURACIÓN DEL SONIDO DICE.MP3 + 1.5s adicionales para coordinación perfecta
    Timer(const Duration(milliseconds: 2500), () { // Aumentado de 1000ms a 2500ms (+ 1.5s)
      // ⏸️ VERIFICAR PAUSA ANTES DE CONTINUAR
      if (isPaused) return;
      
      _timer?.cancel();
      
      // 🧠 CPU ANALIZA EL RESULTADO
      int finalDiceValue = debugMode ? 6 : random.nextInt(6) + 1;
      if (mounted) {
        setState(() {
          diceValue = finalDiceValue;
          lastMessage = _getCPUAnalysisMessage(finalDiceValue);
        });
      }
      
      // ⏱️ PAUSA PARA ANÁLISIS - TIEMPO AUMENTADO PARA LEER BIEN
      _cpuTimer = Timer(const Duration(milliseconds: 2500), () {
        // ⏸️ VERIFICAR PAUSA ANTES DE CONTINUAR
        if (isPaused) return;
        
        if (mounted) {
          setState(() {
            lastMessage = null;
          });
        }
        
        // 🚀 EJECUTAR MOVIMIENTO CON VERIFICACIÓN DE 3 SEISES
        _cpuTimer = Timer(const Duration(milliseconds: 600), () {
          // ⏸️ VERIFICAR PAUSA ANTES DE CONTINUAR
          if (isPaused) return;
          
          if (mounted) {
            _continueWithDiceResult(finalDiceValue);
          }
        });
      });
    });
  }

  // 🎭 MENSAJES ÉPICOS DE PENSAMIENTO CPU - ¡VERSIÓN MEJORADA!
  String _getEpicCPUThinkingMessage() {
    List<String> epicMessages = [
      "🧠 Calculando estrategia maestra...",
      "🎯 Analizando todas las posibilidades...", 
      "⚡ Procesando movimiento perfecto...",
      "🔮 Consultando la matriz del destino...",
      "🎪 Preparando jugada espectacular...",
      "🏆 Diseñando victoria inevitable...",
      "🌟 Activando modo GENIO...",
      "🎭 Tejiendo plan magistral...",
      "⚔️ Forjando estrategia letal...",
      "🎨 Creando obra maestra táctica...",
      "🤖 Iniciando secuencia de dominación...",
      "🚀 Cargando algoritmo de victoria...",
      "💎 Puliendo jugada diamante...",
      "🦅 Planeando vuelo de águila...",
      "🌪️ Generando tormenta táctica...",
      "🎼 Componiendo sinfonía del triunfo...",
      "🔥 Encendiendo llamas de la gloria...",
      "⚗️ Destilando esencia de la victoria...",
      "🎯 Apuntando al corazón del tablero...",
      "🌊 Desatando tsunami estratégico..."
    ];
    return epicMessages[random.nextInt(epicMessages.length)];
  }

  // 📊 MENSAJES DE ANÁLISIS CPU - ¡DRAMÁTICOS Y ÉPICOS!
  String _getCPUAnalysisMessage(int diceValue) {
    List<String> analysisMessages = [
      "🎯 ¡Perfecto! Exactamente lo que necesitaba: $diceValue",
      "⚡ ¡Excelente! Este $diceValue encaja en mi plan",  
      "🎪 ¡Magnífico! Un $diceValue estratégico",
      "🔥 ¡Brillante! Este $diceValue es clave",
      "🌟 ¡Fantástico! $diceValue puntos de pura genialidad",
      "🎭 ¡Espectacular! Un $diceValue muy calculado",
      "⚔️ ¡Letal! Este $diceValue será devastador",
      "🏆 ¡Perfección! $diceValue pasos hacia la gloria",
      "🚀 ¡Increíble! Un $diceValue cósmico",
      "💎 ¡Diamante puro! $diceValue de elegancia",
      "🎼 ¡Sinfonía! $diceValue notas perfectas",
      "🌊 ¡Tsunami! $diceValue olas de poder",
      "🦅 ¡Majestuoso! $diceValue vuelos de águila",
      "🌪️ ¡Tormenta! $diceValue rayos de furia",
      "🔮 ¡Profético! $diceValue del destino",
      "⚗️ ¡Alquimia! $diceValue de oro puro"
    ];
    return analysisMessages[random.nextInt(analysisMessages.length)];
  }

  // 🔄 SISTEMA INTELIGENTE DE TURNOS - Orden aleatorio y solo jugadores activos
  void _nextActivePlayer() {
    // ✅ CICLO CON ORDEN ALEATORIO: Avanzar al siguiente jugador según turnOrder
    do {
      currentTurnIndex = (currentTurnIndex + 1) % widget.numPlayers;
      currentPlayerIndex = turnOrder[currentTurnIndex];
    } while (playerEliminated[currentPlayerIndex]); // Saltar jugadores eliminados
    
    // Resetear contador de auto-lanzamientos si fue el jugador cambiado
    // (no se resetea si el mismo jugador sigue jugando por turnos extra)
    
    // 🎵 Audio de cambio de turno removido para evitar confusión
    // (el sonido 'lanzar_nuevo' sugería algo positivo en cambios normales)
    // Solo mantenemos audio para eventos específicos como logros
    
    // 🤖 AUTO-EJECUTAR TURNO SI ES CPU / ⏰ INICIAR TIMER SI ES HUMANO
    Timer(const Duration(milliseconds: 500), () {
      if (_isCurrentPlayerCPU() && !isMoving) {
        _rollDice();
      } else if (widget.isHuman[currentPlayerIndex] && !isMoving) {
        // Iniciar timer para jugador humano
        _startPlayerTimer();
      }
    });
  }

  // � NUEVA FUNCIÓN: Manejar turnos extra acumulados
  void _handleExtraTurns() {
    if (extraTurnsRemaining > 0) {
      print("🎲 DEBUG: Procesando turno extra. Quedan: $extraTurnsRemaining");
      
      // Mostrar mensaje de turno extra
      String message = extraTurnsRemaining == 1 
          ? "¡Turno extra! 🎲✨" 
          : "¡$extraTurnsRemaining turnos extra restantes! 🎲✨🎲";
      
      _showMessage(message, priority: MessagePriority.normal, durationSeconds: 2);
      
      // Consumir un turno extra
      extraTurnsRemaining--;
      
      // Continuar con el mismo jugador
      Timer(const Duration(milliseconds: 1500), () {
        if (_isCurrentPlayerCPU() && !isMoving) {
          _rollDice(); // CPU lanza automáticamente
        } else if (widget.isHuman[currentPlayerIndex] && !isMoving) {
          _startPlayerTimer(); // Iniciar timer para humano
        }
      });
    } else {
      // No hay más turnos extra, cambiar al siguiente jugador
      print("🔄 DEBUG: No hay más turnos extra, cambiando jugador");
      _nextActivePlayer();
    }
  }

  // �🎲 LÓGICA DE SEISES CONSECUTIVOS - REGLA CLÁSICA DEL PARCHÍS
  void _handleDiceResult(int diceResult) {
    setState(() {
      // 🎯 NUEVA LÓGICA: Ya no manejamos turnos extra por 6 aquí (se hace en _continueWithDiceResult)
      // Solo verificamos si hay turnos extra pendientes para continuar o cambiar jugador
      
      if (diceResult != 6) {
        // Si no es 6, resetear contador de seises consecutivos
        consecutiveSixes = 0;
        hasExtraTurn = false;
      }
      
      // Usar el nuevo sistema de turnos extra acumulables
      _handleExtraTurns();
    });
  }

  void _animateStepByStep(GamePiece piece, int startIndex, int steps) async {
    jumpingPiece = piece; // Marcar cuál ficha está saltando
    
    // 🎯 EFECTO REBOTE: Calcular posición final con rebote si se pasa de la META
    int finalIndex = startIndex + steps;
    int metaIndex = boardPath.length - 1; // Índice de la META (posición 83)
    
    // Si se pasa de la META, implementar efecto rebote
    if (finalIndex > metaIndex) {
      int exceso = finalIndex - metaIndex;
      finalIndex = metaIndex - exceso; // Rebotar hacia atrás
      
      // Asegurarse de que no rebote más allá del inicio
      if (finalIndex < 0) {
        finalIndex = 0;
      }
      
      // Mostrar mensaje del efecto rebote
      setState(() {
        lastMessage = "¡Efecto rebote! Te pasaste por $exceso casillas 🔄";
      });
    }
    
    Position finalPosition = boardPath[finalIndex];
    
    // VERIFICAR LA VÍCTIMA ANTES del movimiento
    GamePiece? victimPiece = _checkForVictim(finalPosition, piece);
    
    // 🎯 ANIMACIÓN CON EFECTO REBOTE (reutilizar metaIndex ya definido)
    
    for (int i = 1; i <= steps; i++) {
      int targetIndex = startIndex + i;
      
      // Si estamos en el proceso de rebote
      if (startIndex + i > metaIndex) {
        // Calcular posición de rebote
        int exceso = (startIndex + i) - metaIndex;
        targetIndex = metaIndex - exceso;
        
        // Asegurarse de no ir más allá del inicio
        if (targetIndex < 0) {
          targetIndex = 0;
        }
        
        // Mensaje especial para el rebote
        if (i == metaIndex - startIndex + 1) {
          setState(() {
            lastMessage = "¡Tocaste la META! Ahora rebotando... 🔄";
          });
          
          // ⏰ Timer para limpiar mensaje de rebote después de 3 segundos
          Timer(const Duration(milliseconds: 3000), () {
            if (mounted) {
              setState(() {
                lastMessage = null;
              });
            }
          });
          
          // 🎵 Sonido de rebote al tocar la META
          AudioService().playBounceEffect();
        }
      } else if (targetIndex >= metaIndex) {
        // Si llega exactamente a la META
        targetIndex = metaIndex;
        
        // 🎵 Sonido al llegar a la META
        AudioService().playGoalEffect();
      }
      
      // Animar el salto
      _jumpController.forward();
      
      // Pequeña pausa para el salto hacia arriba
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Mover a la posición calculada
      setState(() {
        piece.position = boardPath[targetIndex];
      });
      
      // 🎵 Sonido de movimiento de ficha
      AudioService().playPieceMove();
      
      // 🎵 NUEVO: Reproducir sonido de casilla especial si corresponde
      _playSpecialCellSoundAfterMovement(piece.position);
      
      // Completar el salto (bajar)
      await _jumpController.reverse();
      
      // Pausa antes del siguiente salto
      await Future.delayed(const Duration(milliseconds: 150));
    }
    
    // AHORA ejecutar la colisión si había una víctima
    if (victimPiece != null) {
      _executeCollision(piece, victimPiece);
    }

  // ¡NUEVA FUNCIONALIDAD! Verificar casillas especiales con prioridad sobre dados
  bool shouldChangeTurn = await _checkSpecialCell(piece, diceValue);    // � VERIFICAR FINALIZACIÓN: Comprobar si el jugador llegó a la META
    int pieceIndex = boardPath.indexWhere((pos) => 
        pos.row == piece.position.row && pos.col == piece.position.col);
    
    if (pieceIndex == metaIndex) {
      // La ficha llegó exactamente a la META
      // Determinar jugador por color de la ficha
      int playerIndex = piece.color == Colors.red ? 0 :
                       piece.color == Colors.green ? 1 :  
                       piece.color == Colors.yellow ? 2 : 3;
      _checkPlayerFinished(playerIndex);
    }

    // �🎲 LÓGICA DE SEISES CONSECUTIVOS: Manejar el resultado después del movimiento
    setState(() {
      isMoving = false; // Desbloquear el dado
      jumpingPiece = null; // Ya no hay ficha saltando
    });

    // 🎵 VERIFICAR MÚSICA DRAMÁTICA después de cada movimiento
    _checkAndActivateDramaticMusic();

    // Si el juego terminó, no continuar con la lógica de dados
    if (gameEnded) {
      return;
    }

    // Aplicar lógica de seises consecutivos (si debe cambiar turno)
    if (shouldChangeTurn) {
      _handleDiceResult(diceValue);
    } else {
      // 🤖 CASILLA "LANCE DE NUEVO": Activar lanzamiento automático para CPU
      if (_isCurrentPlayerCPU()) {
        // CPU debe lanzar automáticamente después de caer en "LANCE DE NUEVO"
        Timer(const Duration(milliseconds: 1500), () {
          if (!isMoving && mounted) {
            _rollDice(); // Lanzar automáticamente para CPU
          }
        });
      } else {
        // 👤 PARA HUMANOS: Iniciar timer normal si cae en "LANCE DE NUEVO"
        Timer(const Duration(milliseconds: 500), () {
          if (!isMoving && mounted) {
            _startPlayerTimer(); // Iniciar timer para jugador humano
          }
        });
      }
    }
  }

  // Verificar si hay una víctima en la posición de destino (SIN enviarla a SALIDA aún)
  GamePiece? _checkForVictim(Position targetPosition, GamePiece movingPiece) {
    // Solo SALIDA y META son zonas completamente seguras
    bool isSalida = (targetPosition.row == 9 && targetPosition.col == 0);
    bool isMeta = (targetPosition.row == 0 && targetPosition.col == 0);
    
    // Si es SALIDA o META, no hay víctima (zonas seguras)
    if (isSalida || isMeta) {
      return null;
    }
    
    // ✅ TODAS LAS DEMÁS CASILLAS PERMITEN CAPTURAS, incluyendo casillas especiales
    // Esto es correcto según las reglas del Parchís
    
    // Buscar si hay otra ficha en esta posición (excluyendo la que se está moviendo)
    for (GamePiece otherPiece in gamePieces) {
      // Verificar si es ficha del mismo jugador (las fichas del mismo jugador no se capturan)
      bool samePlayer = (movingPiece.color == otherPiece.color);
      
      // Si otra ficha está en la misma posición Y no es la ficha que se está moviendo Y no es del mismo jugador
      if (otherPiece != movingPiece && !samePlayer &&
          otherPiece.position.row == targetPosition.row && 
          otherPiece.position.col == targetPosition.col) {
        return otherPiece; // Retornar la víctima
      }
    }
    
    return null; // No hay víctima
  }

  // Mostrar mensaje de amenaza
  void _showThreatMessage(GamePiece attacker, GamePiece victim) {
    String attackerColor = _getColorName(attacker.color);
    String victimColor = _getColorName(victim.color);
    
    List<String> threatMessages = [
      "¡$attackerColor: 'Voy por ti $victimColor!' 😈",
      "¡$attackerColor se acerca a $victimColor! 👀",
      "¡$attackerColor: 'Prepárate $victimColor!' ⚔️",
      "¡$victimColor está en peligro! 🚨",
      "¡$attackerColor: '$victimColor, tu casilla será mía!' 💀",
      "¡$attackerColor apunta a $victimColor! 🎯",
    ];
    
    String selectedMessage = threatMessages[Random().nextInt(threatMessages.length)];
    
    setState(() {
      lastMessage = selectedMessage;
    });
  }

  // Ejecutar la colisión después de que la ficha llegó al destino
  void _executeCollision(GamePiece attacker, GamePiece victim) {
    // 🎵 ACTIVAR FLAG PARA EVITAR SONIDOS DUPLICADOS
    _isPlayingCollisionAudio = true;
    
    // 🎵 SONIDO ÚNICO DE CAPTURA ÉPICA (sin duplicaciones)
    AudioService().playCaptureSequence();
    
    // Vibración táctil dramática
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 100), () => HapticFeedback.heavyImpact());
    
    String attackerColor = _getColorName(attacker.color);
    String victimColor = _getColorName(victim.color);
    
    // Mensajes de victoria
    List<String> victoryMessages = [
      "¡$attackerColor se comió a $victimColor! 🍽️",
      "¡$victimColor fue enviado de vuelta a casa! 🏠",
      "¡$attackerColor conquistó la casilla! 👑",
      "¡$victimColor tuvo que regresar a SALIDA! 😅",
      "¡$attackerColor ganó la batalla! ⚔️",
      "¡$victimColor regresa a la base! ↩️",
    ];
    
    String selectedMessage = victoryMessages[Random().nextInt(victoryMessages.length)];
    
    // Enviar la víctima a SALIDA y mostrar mensaje de victoria
    setState(() {
      victim.position = const Position(9, 0); // SALIDA
      lastMessage = selectedMessage;
    });
    
    // Mostrar mensaje por 3 segundos
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        lastMessage = null;
      });
      
      // 🎵 DESACTIVAR FLAG DESPUÉS DE QUE TERMINA EL AUDIO
      Timer(const Duration(milliseconds: 500), () {
        _isPlayingCollisionAudio = false;
      });
    });
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return "Rojo";
    if (color == Colors.blue) return "Azul";
    if (color == Colors.green) return "Verde";
    if (color == Colors.yellow) return "Amarillo";
    return "Desconocido";
  }

  // Obtener el nombre del jugador (personalizado o color)
  String _getPlayerName(int playerIndex) {
    return customPlayerNames[playerIndex] ?? playerNames[playerIndex];
  }

  // ¡NUEVA FUNCIÓN SÚPER DIVERTIDA! 🎉 Verificar casillas especiales con mensajes jocosos
  Future<bool> _checkSpecialCell(GamePiece piece, int diceValue) async {
    String playerName = _getPlayerName(currentPlayerIndex);
    String specialText = _getSpecialCellText(piece.position.row, piece.position.col);
    
    if (specialText.isEmpty) return true; // No es casilla especial, cambiar turno normalmente
    
    // 🎵 PREPARAR SONIDO: Solo para casillas que NO causan movimiento inmediato
    if (!_causesMovement(specialText)) {
      _playSpecialCellSound(specialText);
      pendingSpecialCellSound = null; // No hay sonido pendiente
    } else {
      // 🎵 ALMACENAR SONIDO: Para reproducir después del movimiento
      pendingSpecialCellSound = specialText;
    }
    
    // ¡MENSAJES JOCOSOS DOMINICANOS! 🇩🇴
    List<String> messages = [];
    bool skipNextTurn = false;
    bool rollAgain = false;
    Position? newPosition;
    
    switch (specialText) {
      case 'LANCE\nDE\nNUEVO':
        messages = [
          "¡EYYY QUE SUERTE! 🍀",
          "$playerName pegó en la casilla mágica!",
          "¡Tira otra vez como todo un CAMPEÓN! 🎲✨"
        ];
        
        // 🍀 CORRECCIÓN: SIEMPRE agregar 1 turno extra por la casilla especial
        extraTurnsRemaining++;
        print("🍀 DEBUG: Casilla 'LANCE DE NUEVO' agregó turno extra. Total: $extraTurnsRemaining");
        
        // 🎯 MENSAJE ESPECIAL SI HAY DOBLE SUERTE (6 + Lance de Nuevo)
        if (diceValue == 6) {
          messages.add("¡DOBLE SUERTE! Dado 6 + Lance de Nuevo = 2 turnos extra total! 🎲✨🍀");
        }
        
        rollAgain = true;
        break;
        
      case 'VUELVE\nA LA\nSALIDA':
        messages = [
          "¡AYAYAYAYYYY! 😱💥",
          "$playerName cayó en la trampa!",
          "¡De vuelta a la SALIDA como si nada! 🔄😅"
        ];
        newPosition = const Position(9, 0);
        break;
        
      case '1 TURNO\nSIN\nJUGAR':
        messages = [
          "¡A DORMIR LA MONA! 😴💤",
          "$playerName se quedó pegao!",
          "¡Un turno descansando como un bebé! 👶"
        ];
        skipNextTurn = true;
        break;
        
      case 'SUBE\nAL\n63':
        messages = [
          "¡COHETE ESPACIAL! 🚀🌟",
          "$playerName encontró el ascensor!",
          "¡VUELA directo al 63 como Superman! 💫"
        ];
        newPosition = _getPositionFromNumber(63);
        break;
        
      case 'SUBE\nAL\n70':
        messages = [
          "¡TURBOPROPULSADO! 🚀⚡",
          "$playerName activó el jetpack!",
          "¡ZOOM al 70 como Flash! ⚡💨"
        ];
        newPosition = _getPositionFromNumber(70);
        break;
        
      case 'BAJA\nAL\n24':
        messages = [
          "¡TOBOGÁN GIGANTE! 🛝😂",
          "$playerName se resbaló feo!",
          "¡Pa'bajo al 24 como un rayo! ⬇️💨"
        ];
        newPosition = _getPositionFromNumber(24);
        break;
        
      case 'BAJA\nAL\n30':
        messages = [
          "¡ESCALERA MECÁNICA ROTA! 🛝🔧",
          "$playerName bajó de golpe!",
          "¡Directo al 30 sin parar! ⬇️😵"
        ];
        newPosition = _getPositionFromNumber(30);
        break;
        
      case 'BAJA\nAL\n40':
        messages = [
          "¡HUECO EN EL PISO! 🕳️😱",
          "$playerName se hundió!",
          "¡Al 40 como por arte de magia! ⬇️✨"
        ];
        newPosition = _getPositionFromNumber(40);
        break;
        
      case 'BAJA\nAL\n50':
        messages = [
          "¡ASCENSOR ROTO! 🛗💥",
          "$playerName cayó por el tubo!",
          "¡Directo al 50 sin escalas! ⬇️⚡"
        ];
        newPosition = _getPositionFromNumber(50);
        break;
        
      case 'META\nCAMPEON':
        messages = [
          "¡CAMPEONNNNN! 🏆🎉",
          "$playerName llegó a la META!",
          "¡GANASTE como todo un TIGUERRRR! 👑🎊"
        ];
        
        // 🎵 Audio se maneja en _checkPlayerFinished() para evitar duplicación
        // No reproducir audio aquí para prevenir conflictos
        break;
    }
    
    // ¡MOSTRAR MENSAJES CON DRAMA! 🎭 - TIEMPO AUMENTADO PARA LEER BIEN
    for (String message in messages) {
      // 📬 USAR SISTEMA DE COLA PARA MENSAJES ESPECIALES
      _showMessage(message, priority: MessagePriority.special, durationSeconds: 4);
      await Future.delayed(const Duration(seconds: 4)); // Aumentado de 2 a 4 segundos
    }
    
    // ¡EJECUTAR EFECTOS! ✨
    if (newPosition != null) {
      // Animar salto a nueva posición
      _jumpController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      
      setState(() {
        piece.position = newPosition!;
      });
      
      // 🎵 SONIDO SINCRONIZADO: Reproducir cuando la ficha llega visualmente a su destino
      // EVITAR AUDIO DURANTE COLISIONES PARA PREVENIR DUPLICACIÓN
      if (!_isPlayingCollisionAudio) {
        if (newPosition.row == 9 && newPosition.col == 0) {
          // Ficha llegó a SALIDA - sonido de bajar ficha
          AudioService().playPieceDown();
        } else {
          // Ficha llegó a otra posición (teleportación) - sonido de subir ficha
          AudioService().playPieceUp();
        }
      }
      
      await _jumpController.reverse();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Limpiar mensaje
    setState(() {
      currentMessage = '';
    });
    
    // ¡EFECTOS ESPECIALES CON PRIORIDAD SOBRE DADOS! 🎯
    if (skipNextTurn) {
      // 🚨 PRIORIDAD ALTA: Casilla "1 TURNO SIN JUGAR" anula TODOS los beneficios
      setState(() {
        if (diceValue == 6) {
          consecutiveSixes = 0; // Resetear contador porque se pierde el turno extra del 6
        }
        
        // 🚨 CRÍTICO: Anular TODOS los turnos extra acumulados
        if (extraTurnsRemaining > 0) {
          extraTurnsRemaining = 0;
          print("🚨 DEBUG: '1 TURNO SIN JUGAR' anuló $extraTurnsRemaining turnos extra");
        }
      });
      
      // Mensaje de alta prioridad para informar sobre anulación
      String message = "¡Casilla especial anula ";
      if (diceValue == 6 && extraTurnsRemaining > 0) {
        message += "el 6 y los turnos extra";
      } else if (diceValue == 6) {
        message += "el turno extra del 6";
      } else if (extraTurnsRemaining > 0) {
        message += "los turnos extra";
      } else {
        message += "beneficios";
      }
      message += "! 😱";
      
      _showMessage(message, priority: MessagePriority.high, durationSeconds: 3);
      
      // TODO: Implementar skip de siguiente turno cuando sea el turno de este jugador
      print("$playerName debe saltar el próximo turno");
      return true; // Cambiar turno normalmente (saltar se implementará después)
    }
    
    if (rollAgain) {
      // 🎲 CASILLA "LANCE DE NUEVO": Compatible con dado 6
      if (diceValue == 6) {
        // Mensaje normal para doble suerte
        _showMessage("¡Dado 6 + Casilla especial = DOBLE SUERTE! 🍀✨",
            priority: MessagePriority.normal, durationSeconds: 2);
      }
      return false; // No cambiar turno (tirar de nuevo)
    }
    
    // 🎯 CASILLAS CON TELEPORTACIÓN: Mantienen lógica normal de dados
    return true; // Cambiar turno normalmente (permitir lógica de dado 6)
  }
  
  // Función auxiliar para encontrar posición por número
  Position? _getPositionFromNumber(int targetNumber) {
    for (int i = 0; i < boardPath.length; i++) {
      Position pos = boardPath[i];
      if (_getRealBoardNumber(pos.row, pos.col) == targetNumber) {
        return pos;
      }
    }
    return null;
  }

  // 🤖 SISTEMA CPU INTELIGENTE
  String _getCpuThinkingMessage() {
    List<String> messages = [
      '🤖 CPU está pensando...',
      '🧠 Analizando el tablero...',
      '⚡ Calculando jugada...',
      '🎯 Buscando la mejor opción...',
      '🤔 CPU evaluando estrategia...',
      '💭 Procesando movimiento...',
    ];
    
    return messages[Random().nextInt(messages.length)];
  }
  
  // 🚪 DIÁLOGO DE SALIR
  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.exit_to_app,
                color: Color(0xFF5D4037),
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                '¿Salir del juego?',
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro que quieres volver a la configuración? Se perderá el progreso actual.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // � DESACTIVAR WAKELOCK AL SALIR
                _disableWakelock();
                
                // �🔇 DETENER TODOS LOS AUDIOS ANTES DE SALIR
                try {
                  await AudioService().stopAllSounds();
                } catch (e) {
                  print('Error al detener audio al salir: $e');
                }
                
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const PlayerConfigScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Sí, salir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Avatar del usuario actual
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.blue, // Color predeterminado
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    (customPlayerNames[0] ?? 'J')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Parchís Reverse',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '- ${customPlayerNames[0] ?? 'Jugador'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Mensaje del CPU si está activo
                  if (currentMessage.isEmpty && currentPlayerIndex < widget.numPlayers && 
                      !widget.isHuman[currentPlayerIndex] && !isMoving)
                    Text(
                      _getCpuThinkingMessage(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 4,
        automaticallyImplyLeading: false, // Quitar botón atrás de la pantalla de juego
        actions: [
          // 🆕 BOTÓN DE PAUSA
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isPaused ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _togglePauseManually,
              icon: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: isPaused ? Colors.green : Colors.orange,
                size: 24,
              ),
              tooltip: isPaused ? 'Reanudar' : 'Pausar',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD2B48C), Color(0xFFA0805A)],
              ),
            ),
            child: Column(
              children: [
                // Panel de jugadores horizontal - MÓVIL OPTIMIZADO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)], // Mismo color del dado
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Fila de jugadores horizontal
                      Row(
                        children: List.generate(widget.numPlayers, (index) {
                          bool isCurrentPlayer = index == currentPlayerIndex;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _showPlayerProfile(index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: playerEliminated[index]
                                      ? Colors.red.withOpacity(0.2) // Fondo rojo para eliminados
                                      : (isCurrentPlayer 
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.white.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: playerEliminated[index]
                                      ? Border.all(color: Colors.red, width: 2) // Borde rojo para eliminados
                                      : (isCurrentPlayer 
                                          ? Border.all(color: _getPlayerColor(index), width: 2)
                                          : null),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Color + Ícono de estado
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: playerEliminated[index] 
                                                ? Colors.grey[400] // Color gris para eliminados
                                                : _getPlayerColor(index),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getPlayerStatusIcon(index),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    // Nombre del jugador
                                    Text(
                                      playerEliminated[index] ? '💀 ${_getPlayerDisplayName(index)}' : _getPlayerDisplayName(index),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                                        color: playerEliminated[index] ? Colors.red[300] : (isCurrentPlayer ? Colors.black87 : Colors.white),
                                        decoration: playerEliminated[index] ? TextDecoration.lineThrough : null,
                                        decorationColor: playerEliminated[index] ? Colors.red[300] : null,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      
                      // Fila de estado (turno extra y contador de 6s)
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasExtraTurn)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '¡Turno Extra!',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (hasExtraTurn && consecutiveSixes > 0)
                            const SizedBox(width: 8),
                          if (consecutiveSixes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: consecutiveSixes >= 2 ? Colors.red : Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '6s: $consecutiveSixes',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tablero compacto para móvil - CENTRADO
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calcular padding basado en el tamaño de pantalla
                      double screenWidth = constraints.maxWidth;
                      double optimalPadding = screenWidth * 0.02; // Reducido para más espacio
                      
                      return Padding(
                        padding: EdgeInsets.all(optimalPadding),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.01),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E6D3),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 3,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.015),
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: _buildBoard(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Dado y controles en la parte inferior - MÓVIL OPTIMIZADO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Área principal del dado (sin barra de cambios)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Dado centrado
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Lanzar Dado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                
                                // ⏰ TIMER DE JUGADOR HUMANO (solo últimos 5 segundos)
                                if (widget.isHuman[currentPlayerIndex] && !isMoving && timerCountdown <= 5)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isTimerFlashing ? Colors.red.withOpacity(0.8) : Colors.orange.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isTimerFlashing ? Colors.red : Colors.orange,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isTimerFlashing ? Icons.warning : Icons.timer,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${timerCountdown}s',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isTimerFlashing ? 16 : 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _rollDice,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // El dado
                                      AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle: _rotationAnimation.value,
                                            child: Transform.scale(
                                              scale: _scaleAnimation.value,
                                              child: _buildDice(isDecisionTime ? currentDiceResult : diceValue),
                                            ),
                                          );
                                        },
                                      ),
                                      
                                      // Ícono de refresh (solo visible durante decisión para humanos)
                                      if (isDecisionTime && widget.isHuman[currentPlayerIndex])
                                        Container(
                                          margin: const EdgeInsets.only(left: 12),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: remainingChanges[currentPlayerIndex] > 0 
                                                    ? _playerChooseChange 
                                                    : null,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: remainingChanges[currentPlayerIndex] > 0 
                                                        ? Colors.orange.withOpacity(0.8)
                                                        : Colors.grey.withOpacity(0.5),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.refresh,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              // Contador de cambios disponibles
                                              Text(
                                                '${remainingChanges[currentPlayerIndex]}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              // Countdown visual sutil
                                              Text(
                                                '$decisionCountdown',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.orange.shade200,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Popup de mensaje en el centro
          if (priorityMessage != null || lastMessage != null || currentMessage.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sports_esports,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      priorityMessage ?? (currentMessage.isNotEmpty ? currentMessage : (lastMessage ?? '')),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 100,
      itemBuilder: (context, index) {
        int row = index ~/ 10;
        int col = index % 10;
        
        return _buildBoardCell(row, col);
      },
    );
  }

  Widget _buildBoardCell(int row, int col) {
    bool isPath = _isPathCell(row, col);
    int number = _getRealBoardNumber(row, col);
    String specialText = _getSpecialCellText(row, col);
    
    // Verificar si hay fichas en esta posición (EXCLUIR ELIMINADAS)
    List<GamePiece> piecesInThisCell = gamePieces
        .where((piece) => piece.position.row == row && piece.position.col == col && 
                         piece.position.row >= 0 && piece.position.col >= 0) // Excluir fichas eliminadas (-1,-1)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: isPath ? const Color(0xFFE6D3B7) : const Color(0xFFD2B48C),
        border: Border.all(
          color: isPath ? const Color(0xFF8B4513) : const Color(0xFFA0805A),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          if (specialText.isNotEmpty)
            Center(
              child: Text(
                specialText,
                style: TextStyle(
                  fontSize: 6, // Reducido de 7 a 6 especialmente para META CAMPEÓN
                  fontWeight: FontWeight.bold,
                  color: specialText.contains('META') ? Colors.purple : const Color(0xFF5D4037),
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (number > 0)
            Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  fontSize: 12, // Reducido de 16 a 12 para que quepa en las casillas
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          // Mostrar fichas si las hay
          if (piecesInThisCell.isNotEmpty)
            _buildGamePiecesInCell(piecesInThisCell),
        ],
      ),
    );
  }

  Widget _buildGamePiecesInCell(List<GamePiece> pieces) {
    if (pieces.length == 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0), // ✨ Más padding = ficha más pequeña y proporcionada
          child: _buildSingleGamePiece(pieces.first),
        ),
      );
    } else if (pieces.length <= 4) {
      // Organizar las fichas en una cuadrícula 2x2
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(4), // Reducido de 6 a 4 para fichas más grandes
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 4, // Aumentado de 3 a 4
          mainAxisSpacing: 4,  // Aumentado de 3 a 4
        ),
        itemCount: pieces.length,
        itemBuilder: (context, index) {
          return _buildSingleGamePiece(pieces[index]);
        },
      );
    } else {
      // Si hay más de 4 fichas, mostrar solo las primeras 4
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(4), // Reducido de 6 a 4
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 4, // Aumentado de 3 a 4
          mainAxisSpacing: 4,  // Aumentado de 3 a 4
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return _buildSingleGamePiece(pieces[index]);
        },
      );
    }
  }

  Widget _buildSingleGamePiece(GamePiece piece) {
    // Si esta ficha está saltando, aplicar la animación
    if (jumpingPiece == piece) {
      return AnimatedBuilder(
        animation: _jumpAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _jumpAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                color: piece.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.0, // Aumentado de 0.5 a 1.0 para mejor visibilidad
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4), // Aumentado de 0.3 a 0.4
                    spreadRadius: 1.0, // Aumentado de 0.5 a 1.0
                    blurRadius: 2, // Aumentado de 1 a 2
                    offset: const Offset(0, 1), // Aumentado de 0.5 a 1
                  ),
                ],
              ),
              child: Container(), // Sin texto
            ),
          );
        },
      );
    }
    
    // Ficha normal sin animación
    return Container(
      decoration: BoxDecoration(
        color: piece.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.0, // Aumentado de 0.5 a 1.0 para mejor visibilidad
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4), // Aumentado de 0.3 a 0.4
            spreadRadius: 1.0, // Aumentado de 0.5 a 1.0
            blurRadius: 2, // Aumentado de 1 a 2
            offset: const Offset(0, 1), // Aumentado de 0.5 a 1
          ),
        ],
      ),
      child: Container(), // Sin texto
    );
  }

  Widget _buildDice(int value) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8B4513), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: _getDiceDots(value),
    );
  }

  Widget _getDiceDots(int value) {
    Widget dot() => Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );

    switch (value) {
      case 1:
        return Center(
          child: dot(),
        );
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Align(alignment: Alignment.topLeft, child: dot()),
            Align(alignment: Alignment.bottomRight, child: dot()),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Align(alignment: Alignment.topLeft, child: dot()),
            Center(child: dot()),
            Align(alignment: Alignment.bottomRight, child: dot()),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [dot(), dot()],
            ),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [dot(), dot()],
            ),
            Center(child: dot()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [dot(), dot()],
            ),
          ],
        );
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [dot(), dot()],
            ),
          ],
        );
      default:
        return Center(child: dot());
    }
  }

  bool _isPathCell(int row, int col) {
    // Todas las casillas con números o texto especial son parte del juego
    return _getRealBoardNumber(row, col) > 0 || _getSpecialCellText(row, col).isNotEmpty;
  }

  String _getSpecialCellText(int row, int col) {
    // Basado exactamente en la imagen del tablero real
    Map<String, String> specialCells = {
      // Casillas especiales según la imagen
      '9,0': 'SALIDA',
      '8,3': 'LANCE\nDE\nNUEVO',
      '8,7': 'VUELVE\nA LA\nSALIDA',
      '7,1': '1 TURNO\nSIN\nJUGAR',
      '7,7': 'SUBE\nAL\n63',
      '6,7': 'LANCE\nDE\nNUEVO',
      '5,8': 'BAJA\nAL\n24',
      '5,1': '1 TURNO\nSIN\nJUGAR',
      '4,5': 'SUBE\nAL\n70',
      '3,3': 'BAJA\nAL\n30',
      '3,9': 'LANCE\nDE\nNUEVO',
      '2,5': '1 TURNO\nSIN\nJUGAR',
      '1,7': 'BAJA\nAL\n40',
      '1,2': '1 TURNO\nSIN\nJUGAR',
      '0,8': 'LANCE\nDE\nNUEVO',
      '0,3': 'BAJA\nAL\n50',
      '0,0': 'META\nCAMPEON',
    };
    
    String key = '$row,$col';
    return specialCells[key] ?? '';
  }

  int _getRealBoardNumber(int row, int col) {
    // Mapeo completo del tablero real basado exactamente en la imagen
    Map<String, int> boardNumbers = {
      // Fila 0 (superior)
      '0,1': 83, '0,2': 82, '0,4': 81, '0,5': 80, '0,6': 79, '0,7': 78, '0,9': 77,
      
      // Fila 1
      '1,0': 69, '1,1': 70, '1,3': 71, '1,4': 72, '1,5': 73, '1,6': 74, '1,8': 75, '1,9': 76,
      
      // Fila 2
      '2,0': 68, '2,1': 67, '2,2': 66, '2,3': 65, '2,4': 64, '2,6': 63, '2,7': 62, '2,8': 61, '2,9': 60,
      
      // Fila 3
      '3,0': 52, '3,1': 53, '3,2': 54, '3,4': 55, '3,5': 56, '3,6': 57, '3,7': 58, '3,8': 59,
      
      // Fila 4
      '4,0': 51, '4,1': 50, '4,2': 49, '4,3': 48, '4,4': 47, '4,6': 46, '4,7': 45, '4,8': 44, '4,9': 43,
      
      // Fila 5
      '5,0': 35, '5,2': 36, '5,3': 37, '5,4': 38, '5,5': 39, '5,6': 40, '5,7': 41, '5,9': 42,
      
      // Fila 6
      '6,0': 34, '6,1': 33, '6,2': 32, '6,3': 31, '6,4': 30, '6,5': 29, '6,6': 28, '6,8': 27, '6,9': 26,
      
      // Fila 7
      '7,0': 18, '7,2': 19, '7,3': 20, '7,4': 21, '7,5': 22, '7,6': 23, '7,8': 24, '7,9': 25,
      
      // Fila 8
      '8,0': 17, '8,1': 16, '8,2': 15, '8,4': 14, '8,5': 13, '8,6': 12, '8,8': 11, '8,9': 10,
      
      // Fila 9 (inferior)
      '9,1': 1, '9,2': 2, '9,3': 3, '9,4': 4, '9,5': 5, '9,6': 6, '9,7': 7, '9,8': 8, '9,9': 9,
    };
    
    String key = '$row,$col';
    return boardNumbers[key] ?? 0;
  }
}