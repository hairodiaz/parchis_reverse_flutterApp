import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

// Modelo de datos de usuario
class User {
  final String id;
  final String name;
  final Color avatarColor;
  final String level;
  final int gamesPlayed;
  final int gamesWon;
  
  const User({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.level,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
  });
  
  double get winRate => gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;
}

// Gestor de usuarios predeterminados
class UserManager {
  static final List<User> predefinedUsers = [
    User(
      id: 'hairo',
      name: 'Hairo',
      avatarColor: Colors.blue,
      level: 'Pro',
      gamesPlayed: 45,
      gamesWon: 32,
    ),
    User(
      id: 'maria',
      name: 'María',
      avatarColor: Colors.pink,
      level: 'Intermedio',
      gamesPlayed: 23,
      gamesWon: 12,
    ),
    User(
      id: 'carlos',
      name: 'Carlos',
      avatarColor: Colors.green,
      level: 'Experto',
      gamesPlayed: 67,
      gamesWon: 51,
    ),
    User(
      id: 'ana',
      name: 'Ana',
      avatarColor: Colors.orange,
      level: 'Principiante',
      gamesPlayed: 8,
      gamesWon: 3,
    ),
  ];
  
  static User? currentUser;
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

void main() {
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
      home: const LoginScreen(), // Comenzar con la pantalla de login
      debugShowCheckedModeBanner: false,
    );
  }
}

// 🔐 PANTALLA DE LOGIN
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Azul oscuro
              Color(0xFF3B82F6), // Azul medio
              Color(0xFF60A5FA), // Azul claro
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Logo y título
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.games,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Parchís Reverse',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Dominicano',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Título de selección
                const Text(
                  'Selecciona tu perfil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Lista de usuarios
                Expanded(
                  child: ListView.builder(
                    itemCount: UserManager.predefinedUsers.length,
                    itemBuilder: (context, index) {
                      final user = UserManager.predefinedUsers[index];
                      return _buildUserCard(context, user);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _loginUser(context, user),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: user.avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: user.avatarColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Información del usuario
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
                      Text(
                        'Nivel: ${user.level}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: Colors.orange[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.gamesWon}/${user.gamesPlayed} ganadas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${user.winRate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: user.winRate >= 50 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Icono de entrada
                Icon(
                  Icons.arrow_forward_ios,
                  color: user.avatarColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _loginUser(BuildContext context, User user) {
    UserManager.currentUser = user;
    
    // Navegar al juego
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
  }
}

// 🎬 PANTALLA DE CARGA (SPLASH SCREEN)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    
    // Animación del logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    // Animación del texto
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    _startAnimations();
  }
  
  void _startAnimations() async {
    // Animar logo
    _logoController.forward();
    
    // Esperar un poco y animar texto
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    
    // Esperar y navegar al menú principal
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2), // Azul dominicano
              Color(0xFF0D47A1), // Azul más oscuro
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              AnimatedBuilder(
                animation: _logoScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 5,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_esports,
                        size: 80,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              // Título animado
              AnimatedBuilder(
                animation: _textFade,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFade.value,
                    child: Column(
                      children: [
                        const Text(
                          '🎲 PARCHÍS REVERSE',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'DOMINICANO 🇩🇴',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // Indicador de carga
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Cargando...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🏠 PANTALLA PRINCIPAL DEL MENÚ - ¡PROFESIONAL!
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _buttonsController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _buttonsAnimation;

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
    
    _startAnimations();
  }
  
  void _startAnimations() async {
    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _buttonsController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _buttonsController.dispose();
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(Colors.blue.shade900, Colors.purple.shade900, _backgroundAnimation.value)!,
                  Color.lerp(Colors.purple.shade900, Colors.indigo.shade900, _backgroundAnimation.value)!,
                  Color.lerp(Colors.indigo.shade900, Colors.blue.shade900, _backgroundAnimation.value)!,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 🎯 TÍTULO PRINCIPAL
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: FadeTransition(
                      opacity: _backgroundAnimation,
                      child: const Text(
                        '🎲 PARCHÍS REVERSE\nDOMINICANO',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black54,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _buttonsAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _buttonsAnimation.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🎮 BOTÓN JUGAR
                                _buildMenuButton(
                                  icon: Icons.play_arrow_rounded,
                                  title: 'JUGAR',
                                  subtitle: 'Iniciar nueva partida',
                                  colors: [Colors.green.shade400, Colors.green.shade600],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PlayerConfigScreen(),
                                      ),
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // ℹ️ BOTÓN ACERCA DE
                                _buildMenuButton(
                                  icon: Icons.info_outline_rounded,
                                  title: 'ACERCA DE',
                                  subtitle: 'Información y créditos',
                                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                                  onTap: () {
                                    _showAboutDialog();
                                  },
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // 🚪 BOTÓN CERRAR SESIÓN
                                _buildMenuButton(
                                  icon: Icons.logout_rounded,
                                  title: 'CERRAR SESIÓN',
                                  subtitle: UserManager.currentUser != null 
                                      ? 'Salir como ${UserManager.currentUser!.name}'
                                      : 'Volver al login',
                                  colors: [Colors.red.shade400, Colors.red.shade600],
                                  onTap: () {
                                    _showLogoutDialog();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // 👨‍💻 CRÉDITOS EN LA PARTE INFERIOR
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: FadeTransition(
                      opacity: _backgroundAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'Desarrollado por',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            'Ing. Hairo Díaz',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 28),
              SizedBox(width: 10),
              Text(
                'Acerca de',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎲 Parchís Reverse Dominicano',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Versión: 1.0.0',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 15),
                Text(
                  '📱 Características:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('• 2-4 jugadores (Humanos y CPU)'),
                Text('• CPU inteligente con personalidad'),
                Text('• Casillas especiales divertidas'),
                Text('• Efectos visuales y sonoros'),
                Text('• Interfaz responsive y moderna'),
                SizedBox(height: 15),
                Text(
                  '👨‍💻 Desarrollador:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ing. Hairo Díaz',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ingeniero de Software especializado en desarrollo móvil con Flutter/Dart',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 15),
                Text(
                  '🏆 Hecho con ❤️ en República Dominicana',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
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
        );
      },
    );
  }

  void _showLogoutDialog() {
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
                Icons.logout_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                '¿Cerrar sesión?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (UserManager.currentUser != null) ...[
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: UserManager.currentUser!.avatarColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          UserManager.currentUser!.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UserManager.currentUser!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Nivel: ${UserManager.currentUser!.level}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Text(
                '¿Estás seguro de que quieres cerrar sesión y volver al login?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                UserManager.currentUser = null; // Limpiar usuario
                
                // Navegar al login y limpiar toda la pila de navegación
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cerrar sesión',
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
  List<Color> playerColors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
  List<String> colorNames = ['Rojo', 'Azul', 'Verde', 'Amarillo'];

  @override
  void initState() {
    super.initState();
    
    // Si hay usuario logueado, configurar su nombre en Jugador 1
    if (UserManager.currentUser != null) {
      playerNames[0] = UserManager.currentUser!.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (UserManager.currentUser != null)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: UserManager.currentUser!.avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    UserManager.currentUser!.name[0].toUpperCase(),
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
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
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
                        child: Row(
                          children: [
                            // Color del jugador
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: playerColors[index],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                            const SizedBox(width: 15),
                            
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
                                    enabled: !(index == 0 && UserManager.currentUser != null), // Deshabilitar para Jugador 1 si hay usuario logueado
                                    decoration: InputDecoration(
                                      hintText: index == 0 && UserManager.currentUser != null 
                                          ? '👤 Usuario logueado' 
                                          : 'Nombre del jugador',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      suffixIcon: index == 0 && UserManager.currentUser != null 
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
                                      color: index == 0 && UserManager.currentUser != null 
                                          ? Colors.grey[600] 
                                          : Colors.black,
                                    ),
                                    controller: TextEditingController(
                                      text: playerNames[index],
                                    ),
                                    onChanged: (value) {
                                      // Solo permitir cambios si no es el usuario logueado
                                      if (!(index == 0 && UserManager.currentUser != null)) {
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
                            
                            // Selector CPU/Humano
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isHuman[index] = !isHuman[index];
                                  if (!isHuman[index]) {
                                    playerNames[index] = 'CPU ${index + 1}';
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15, 
                                  vertical: 8
                                ),
                                decoration: BoxDecoration(
                                  color: isHuman[index] 
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isHuman[index] 
                                        ? Colors.green
                                        : Colors.orange,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isHuman[index] 
                                          ? Icons.person 
                                          : Icons.smart_toy,
                                      size: 20,
                                      color: isHuman[index] 
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isHuman[index] ? 'HUMANO' : 'CPU',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isHuman[index] 
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                      ),
                                    ),
                                  ],
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
                    onPressed: () {
                      // Navegar al juego con la configuración
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ParchisBoard(
                            numPlayers: numPlayers,
                            playerNames: playerNames.take(numPlayers).toList(),
                            isHuman: isHuman.take(numPlayers).toList(),
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
  
  const ParchisBoard({
    super.key,
    this.numPlayers = 4,
    this.playerNames = const ['Rojo', 'Azul', 'Verde', 'Amarillo'],
    this.isHuman = const [true, true, true, true],
  });

  @override
  State<ParchisBoard> createState() => _ParchisBoardState();
}

class _ParchisBoardState extends State<ParchisBoard> with TickerProviderStateMixin {
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
  int currentPlayerIndex = 0; // 0=rojo, 1=azul, 2=verde, 3=amarillo
  List<Color> playerColors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
  List<String> playerNames = ['Rojo', 'Azul', 'Verde', 'Amarillo'];
  List<String?> customPlayerNames = [null, null, null, null]; // Nombres personalizados (null = usar color)
  
  // 🎲 REGLAS CLÁSICAS DEL PARCHÍS
  int consecutiveSixes = 0; // Contador de seises consecutivos
  bool hasExtraTurn = false; // Indica si el jugador tiene turno extra por sacar 6
  bool isMoving = false; // Para bloquear el dado mientras se mueve una ficha
  GamePiece? jumpingPiece; // Para saber qué ficha está saltando
  
  // Variables para mensajes jocosos
  String? lastMessage;
  Timer? _messageTimer;
  String currentMessage = ''; // Para mensajes de casillas especiales
  
  // Ruta de movimiento en el tablero (secuencia de posiciones)
  List<Position> boardPath = [];

  // � SISTEMA DE CAMBIO DE JUGADAS
  List<int> remainingChanges = [3, 3, 3, 3]; // Cambios disponibles por jugador
  bool isDecisionTime = false; // ¿Está el jugador decidiendo si cambiar?
  int currentDiceResult = 0; // Resultado actual del dado
  Timer? _decisionTimer; // Timer para auto-continuar
  int decisionCountdown = 3; // Countdown de 3 segundos

  // �👤 SISTEMA DE PERFILES DE JUGADORES
  
  // Obtener nombre del jugador con formato correcto
  String _getPlayerDisplayName(int playerIndex) {
    if (playerIndex == 0 && widget.isHuman[0]) {
      // Si es el jugador humano y hay usuario logueado, usar su nombre
      if (UserManager.currentUser != null) {
        return UserManager.currentUser!.name;
      }
      return customPlayerNames[0] ?? 'HUMANO';
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
      lastMessage = "🔄 ¡Cambiando jugada! (${remainingChanges[currentPlayerIndex]} cambios restantes)";
    });

    // 🎯 GENERAR NUEVO RESULTADO ANTES de la animación
    int newFinalResult = Random().nextInt(6) + 1;

    // Nuevo lanzamiento de dado
    _playDiceSound();
    _animationController.reset();
    _animationController.forward();
    
    Timer? newDiceTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        currentDiceResult = Random().nextInt(6) + 1; // Animación aleatoria
      });
    });

    Timer(const Duration(milliseconds: 800), () {
      newDiceTimer?.cancel();
      
      setState(() {
        currentDiceResult = newFinalResult; // Asignar resultado final SIN cambio brusco
        lastMessage = "🎲 Nuevo resultado: $newFinalResult";
      });

      Timer(const Duration(milliseconds: 1000), () {
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

  // Continuar el juego con el resultado final
  void _continueWithDiceResult(int finalResult) {
    setState(() {
      diceValue = finalResult;
      isMoving = true; // Asegurar que el dado esté bloqueado
    });
    
    // Pausa de 2 segundos antes de empezar el movimiento para evitar sensación de "cargado"
    Timer(const Duration(milliseconds: 2000), () {
      Timer(const Duration(milliseconds: 200), () {
        bool hasThreats = _checkAndShowThreatMessage(finalResult);
        
        if (hasThreats) {
          Timer(const Duration(milliseconds: 1500), () {
            setState(() {
              lastMessage = null;
            });
            
            Timer(const Duration(milliseconds: 300), () {
              _moveCurrentPlayerPiece(finalResult);
            });
          });
        } else {
          Timer(const Duration(milliseconds: 400), () {
            _moveCurrentPlayerPiece(finalResult);
          });
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    
    // Configurar jugadores según la pantalla de configuración
    for (int i = 0; i < widget.numPlayers; i++) {
      customPlayerNames[i] = widget.playerNames[i];
    }
    
    // Si hay usuario logueado y es el jugador 1, usar su nombre
    if (UserManager.currentUser != null && widget.isHuman[0]) {
      customPlayerNames[0] = UserManager.currentUser!.name;
    }
    
    // 🎮 AUTO-INICIAR SI EL PRIMER JUGADOR ES CPU
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 1000), () {
        if (_isCurrentPlayerCPU() && !isMoving) {
          _rollDice();
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
    // Vibración táctil para simular el dado rodando
    HapticFeedback.heavyImpact();
    
    // Secuencia de vibraciones cortas para simular el dado rebotando
    Timer(const Duration(milliseconds: 100), () => HapticFeedback.mediumImpact());
    Timer(const Duration(milliseconds: 200), () => HapticFeedback.lightImpact());
    Timer(const Duration(milliseconds: 300), () => HapticFeedback.mediumImpact());
    Timer(const Duration(milliseconds: 400), () => HapticFeedback.lightImpact());
    Timer(const Duration(milliseconds: 600), () => HapticFeedback.heavyImpact()); // Final del dado
  }
  
  void _playCollisionSound() {
    // Sonido dramático para comer fichas
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 100), () => HapticFeedback.heavyImpact());
  }
  
  void _playSpecialCellSound(String cellType) {
    switch (cellType) {
      case 'LANCE\nDE\nNUEVO':
        // Sonido de suerte
        HapticFeedback.lightImpact();
        Timer(const Duration(milliseconds: 100), () => HapticFeedback.lightImpact());
        Timer(const Duration(milliseconds: 200), () => HapticFeedback.mediumImpact());
        break;
      case 'VUELVE\nA LA\nSALIDA':
        // Sonido de caída dramática
        HapticFeedback.heavyImpact();
        Timer(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
        Timer(const Duration(milliseconds: 400), () => HapticFeedback.heavyImpact());
        break;
      case '1 TURNO\nSIN\nJUGAR':
        // Sonido de "dormir"
        HapticFeedback.mediumImpact();
        Timer(const Duration(milliseconds: 300), () => HapticFeedback.lightImpact());
        break;
      default:
        // Sonido genérico para subir/bajar
        HapticFeedback.mediumImpact();
        Timer(const Duration(milliseconds: 150), () => HapticFeedback.mediumImpact());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageTimer?.cancel();
    _animationController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  void _rollDice() {
    if (_timer != null && _timer!.isActive) return;
    if (isMoving) return; // No permitir lanzar dado mientras se mueve una ficha
    
    // 🤖 SISTEMA CPU INTELIGENTE - ¡ÉPICO!
    if (_isCurrentPlayerCPU()) {
      _executeCPUTurn();
      return;
    }
    
    // ¡SONIDO DEL DADO! 🎵
    _playDiceSound();
    
    // 🎯 GENERAR RESULTADO FINAL ANTES de la animación
    int finalDiceResult = random.nextInt(6) + 1;
    
    _animationController.reset();
    _animationController.forward();
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        diceValue = random.nextInt(6) + 1; // Animación aleatoria
      });
    });

    Timer(const Duration(milliseconds: 800), () {
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

    Timer(const Duration(milliseconds: 800), () {
      _timer?.cancel();
      
      // 🧠 CPU ANALIZA EL RESULTADO
      int finalDiceValue = random.nextInt(6) + 1;
      if (mounted) {
        setState(() {
          diceValue = finalDiceValue;
          lastMessage = _getCPUAnalysisMessage(finalDiceValue);
        });
      }
      
      // ⏱️ PAUSA PARA ANÁLISIS - TIEMPO AUMENTADO PARA LEER BIEN
      Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            lastMessage = null;
          });
        }
        
        // 🚀 EJECUTAR MOVIMIENTO
        Timer(const Duration(milliseconds: 600), () {
          if (mounted) {
            _moveCurrentPlayerPiece(finalDiceValue);
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

  // 🔄 SISTEMA INTELIGENTE DE TURNOS - Solo jugadores activos
  void _nextActivePlayer() {
    // ✅ CICLO CORRECTO: Solo entre jugadores activos (0 hasta numPlayers-1)
    currentPlayerIndex = (currentPlayerIndex + 1) % widget.numPlayers;
             
    // 🤖 AUTO-EJECUTAR TURNO SI ES CPU
    Timer(const Duration(milliseconds: 500), () {
      if (_isCurrentPlayerCPU() && !isMoving) {
        _rollDice();
      }
    });
  }

  // 🎲 LÓGICA DE SEISES CONSECUTIVOS - REGLA CLÁSICA DEL PARCHÍS
  void _handleDiceResult(int diceResult) {
    setState(() {
      if (diceResult == 6) {
        consecutiveSixes++;
        hasExtraTurn = true;
        
        // 🚨 PENALIZACIÓN: 3 seises consecutivos
        if (consecutiveSixes >= 3) {
          lastMessage = "¡3 seises consecutivos! ¡Pierdes el turno! 😱";
          consecutiveSixes = 0;
          hasExtraTurn = false;
          
          // Cambiar turno después de mostrar el mensaje
          Timer(const Duration(milliseconds: 2000), () {
            setState(() {
              lastMessage = null;
              _nextActivePlayer();
            });
            
            // 🤖 SI EL NUEVO JUGADOR ES CPU: Continuar automáticamente
            Timer(const Duration(milliseconds: 500), () {
              if (_isCurrentPlayerCPU() && !isMoving) {
                _rollDice();
              }
            });
          });
          return;
        } else {
          // ✅ TURNO EXTRA POR SACAR 6
          String extraTurnMessage = consecutiveSixes == 1 
              ? "¡Sacaste 6! ¡Turno extra! 🎲✨"
              : "¡Segundo 6! ¡Cuidado con el tercero! ⚠️🎲";
          lastMessage = extraTurnMessage;
          
          // Quitar mensaje después de un tiempo
          Timer(const Duration(milliseconds: 1500), () {
            setState(() {
              lastMessage = null;
            });
            
            // 🤖 SI ES CPU: Continuar automáticamente con el turno extra
            if (_isCurrentPlayerCPU() && !isMoving) {
              Timer(const Duration(milliseconds: 500), () {
                _rollDice();
              });
            }
          });
        }
      } else {
        // 🔄 NO ES 6: Resetear contador y cambiar turno
        consecutiveSixes = 0;
        hasExtraTurn = false;
        _nextActivePlayer();
      }
    });
  }

  void _animateStepByStep(GamePiece piece, int startIndex, int steps) async {
    jumpingPiece = piece; // Marcar cuál ficha está saltando
    
    // Calcular la posición final primero
    int finalIndex = startIndex + steps;
    if (finalIndex >= boardPath.length) {
      finalIndex = boardPath.length - 1; // META CAMPEÓN
    }
    Position finalPosition = boardPath[finalIndex];
    
    // VERIFICAR LA VÍCTIMA ANTES del movimiento
    GamePiece? victimPiece = _checkForVictim(finalPosition, piece);
    
    for (int i = 1; i <= steps; i++) {
      int newIndex = startIndex + i;
      
      // Verificar que no se pase del final
      if (newIndex >= boardPath.length) {
        newIndex = boardPath.length - 1; // META CAMPEÓN
      }
      
      // Animar el salto
      _jumpController.forward();
      
      // Pequeña pausa para el salto hacia arriba
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Mover a la siguiente casilla mientras está en el aire (SIN verificar colisión aquí)
      setState(() {
        piece.position = boardPath[newIndex];
      });
      
      // Completar el salto (bajar)
      await _jumpController.reverse();
      
      // Si llegó al final, salir del bucle
      if (newIndex >= boardPath.length - 1) break;
      
      // Pausa antes del siguiente salto
      await Future.delayed(const Duration(milliseconds: 150));
    }
    
    // AHORA ejecutar la colisión si había una víctima
    if (victimPiece != null) {
      _executeCollision(piece, victimPiece);
    }

    // ¡NUEVA FUNCIONALIDAD! Verificar casillas especiales
    bool shouldChangeTurn = await _checkSpecialCell(piece);

    // 🎲 LÓGICA DE SEISES CONSECUTIVOS: Manejar el resultado después del movimiento
    setState(() {
      isMoving = false; // Desbloquear el dado
      jumpingPiece = null; // Ya no hay ficha saltando
    });

    // Aplicar lógica de seises consecutivos (si debe cambiar turno)
    if (shouldChangeTurn) {
      _handleDiceResult(diceValue);
    }
  }

  // Verificar si hay una víctima en la posición de destino (SIN enviarla a SALIDA aún)
  GamePiece? _checkForVictim(Position targetPosition, GamePiece movingPiece) {
    // Posiciones especiales donde pueden coexistir fichas
    bool isSalida = (targetPosition.row == 9 && targetPosition.col == 0);
    bool isMeta = (targetPosition.row == 0 && targetPosition.col == 0);
    
    // Si es SALIDA o META, no hay víctima
    if (isSalida || isMeta) {
      return null;
    }
    
    // Buscar si hay otra ficha en esta posición (excluyendo la que se está moviendo)
    for (GamePiece otherPiece in gamePieces) {
      // Si otra ficha está en la misma posición Y no es la ficha que se está moviendo
      if (otherPiece != movingPiece &&
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
    // ¡SONIDO DRAMÁTICO DE COLISIÓN! 💥
    _playCollisionSound();
    
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
  Future<bool> _checkSpecialCell(GamePiece piece) async {
    String playerName = _getPlayerName(currentPlayerIndex);
    String specialText = _getSpecialCellText(piece.position.row, piece.position.col);
    
    if (specialText.isEmpty) return true; // No es casilla especial, cambiar turno normalmente
    
    // ¡SONIDO DE CASILLA ESPECIAL! 🎵
    _playSpecialCellSound(specialText);
    
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
        break;
    }
    
    // ¡MOSTRAR MENSAJES CON DRAMA! 🎭
    for (String message in messages) {
      setState(() {
        currentMessage = message;
      });
      await Future.delayed(const Duration(seconds: 2));
    }
    
    // ¡EJECUTAR EFECTOS! ✨
    if (newPosition != null) {
      // Animar salto a nueva posición
      _jumpController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      
      setState(() {
        piece.position = newPosition!;
      });
      
      await _jumpController.reverse();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Limpiar mensaje
    setState(() {
      currentMessage = '';
    });
    
    // ¡EFECTOS ESPECIALES!
    if (skipNextTurn) {
      // Marcar jugador para saltar próximo turno (implementar después)
      print("$playerName debe saltar el próximo turno");
    }
    
    if (rollAgain) {
      // No cambiar jugador, permitir tirar de nuevo
      return false; // No cambiar turno
    }
    
    return true; // Cambiar turno normalmente
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

  // Construir el indicador de jugador para las esquinas - ¡VERSIÓN ÉPICA!
  Widget _buildPlayerIndicator(int playerIndex) {
    bool isCurrentPlayer = currentPlayerIndex == playerIndex;
    bool isCPU = !widget.isHuman[playerIndex];
    bool isCPUThinking = isCurrentPlayer && isCPU && isMoving;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentPlayer 
          ? (isCPUThinking 
             ? Colors.purple.withOpacity(0.9)  // 🤖 COLOR ÉPICO PARA CPU PENSANDO
             : Colors.white.withOpacity(0.9)) 
          : Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPlayer 
            ? (isCPUThinking
               ? Colors.purple.shade300  // 🌟 BORDE MÁGICO
               : (playerColors[playerIndex] == Colors.yellow 
                  ? Colors.orange.shade700  
                  : playerColors[playerIndex]))
            : Colors.white.withOpacity(0.5),
          width: isCurrentPlayer ? (isCPUThinking ? 4 : 3) : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCPUThinking 
              ? Colors.purple.withOpacity(0.8)  // ✨ SOMBRA MÁGICA
              : Colors.black.withOpacity(0.3),
            spreadRadius: isCPUThinking ? 3 : 1,
            blurRadius: isCPUThinking ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo con la ficha del jugador
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: playerColors[playerIndex],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Nombre del jugador con efectos épicos
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getPlayerName(playerIndex),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.w500,
                  color: isCurrentPlayer 
                    ? (isCPUThinking
                       ? Colors.white  // 🤖 TEXTO BLANCO PARA CPU PENSANDO
                       : (playerColors[playerIndex] == Colors.yellow 
                          ? Colors.orange.shade700  
                          : playerColors[playerIndex]))
                    : Colors.white,
                ),
              ),
              // 🤖 ICONO ESPECIAL PARA CPU
              if (isCPU) ...[
                const SizedBox(width: 3),
                Icon(
                  isCPUThinking ? Icons.psychology : Icons.smart_toy,
                  size: 12,
                  color: isCurrentPlayer 
                    ? (isCPUThinking ? Colors.yellow : Colors.grey.shade600)
                    : Colors.grey.shade400,
                ),
              ],
              // ⚡ EFECTO ESPECIAL CUANDO CPU ESTÁ PENSANDO
              if (isCPUThinking) ...[
                const SizedBox(width: 2),
                const SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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
              onPressed: () {
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
            if (UserManager.currentUser != null)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: UserManager.currentUser!.avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    UserManager.currentUser!.name[0].toUpperCase(),
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
                      if (UserManager.currentUser != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '- ${UserManager.currentUser!.name}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
          // Botón de configuración
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _showExitDialog,
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Configuración',
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
                                  color: isCurrentPlayer 
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isCurrentPlayer 
                                      ? Border.all(color: _getPlayerColor(index), width: 2)
                                      : null,
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
                                            color: _getPlayerColor(index),
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
                                      _getPlayerDisplayName(index),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                                        color: isCurrentPlayer ? Colors.black87 : Colors.white,
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
          if (lastMessage != null || currentMessage.isNotEmpty)
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
                      currentMessage.isNotEmpty ? currentMessage : (lastMessage ?? ''),
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
    
    // Verificar si hay fichas en esta posición
    List<GamePiece> piecesInThisCell = gamePieces
        .where((piece) => piece.position.row == row && piece.position.col == col)
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