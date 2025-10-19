import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../models/local_user.dart';

/// 🔐 PANTALLA DE LOGIN/REGISTRO
/// 
/// Funcionalidades:
/// - 📱 Login con Facebook/Google
/// - 👤 Continuar como invitado
/// - 🔄 Migración automática de datos
/// - 📊 Mostrar beneficios del registro
class LoginScreen extends StatefulWidget {
  final bool showGuestOption;
  
  const LoginScreen({
    super.key,
    this.showGuestOption = true,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with TickerProviderStateMixin {
  
  bool _isLoading = false;
  String _loadingMessage = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // 📱 Login con Facebook
  Future<void> _loginWithFacebook() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Conectando con Facebook...';
    });

    try {
      LocalUser? user = await AuthService().signInWithFacebook();
      
      if (user != null) {
        _showSuccessMessage('¡Bienvenido! Tu cuenta ha sido vinculada exitosamente');
        _navigateToMainMenu();
      } else {
        _showErrorMessage('No se pudo conectar con Facebook. Inténtalo de nuevo.');
      }
    } catch (e) {
      _showErrorMessage('Error de conexión. Verifica tu internet e inténtalo de nuevo.');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  // 🔍 Login con Google
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Conectando con Google...';
    });

    try {
      LocalUser? user = await AuthService().signInWithGoogle();
      
      if (user != null) {
        _showSuccessMessage('¡Bienvenido! Tu cuenta ha sido vinculada exitosamente');
        _navigateToMainMenu();
      } else {
        _showErrorMessage('No se pudo conectar con Google. Inténtalo de nuevo.');
      }
    } catch (e) {
      _showErrorMessage('Error de conexión. Verifica tu internet e inténtalo de nuevo.');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  // 👤 Continuar como invitado
  Future<void> _continueAsGuest() async {
    // Verificar que tenemos un usuario invitado
    final currentUser = HiveService.getCurrentUser();
    
    if (currentUser == null) {
      // Crear usuario invitado si no existe
      await HiveService.createGuestUser();
    }
    
    _navigateToMainMenu();
  }

  // 🚀 Navegar al menú principal
  void _navigateToMainMenu() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  // ✅ Mostrar mensaje de éxito
  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ❌ Mostrar mensaje de error
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade600,
              Colors.deepPurple.shade300,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading ? _buildLoadingScreen() : _buildLoginScreen(),
        ),
      ),
    );
  }

  // 🔄 Pantalla de carga
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        spreadRadius: 4,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    size: 40,
                    color: Colors.deepPurple,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            _loadingMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  // 🔐 Pantalla de login principal
  Widget _buildLoginScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          
          // 🎮 Logo y título
          _buildHeader(),
          
          const Spacer(),
          
          // 📊 Beneficios del registro
          _buildBenefitsSection(),
          
          const SizedBox(height: 32),
          
          // 🔐 Botones de login
          _buildLoginButtons(),
          
          const SizedBox(height: 24),
          
          // 👤 Opción de invitado
          if (widget.showGuestOption) _buildGuestOption(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 🎮 Header con logo
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 4,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.games,
            size: 60,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Parchis Reverse',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conecta tu cuenta para una mejor experiencia',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 📊 Sección de beneficios
  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎯 Beneficios de Registrarte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.backup,
            title: 'Respaldo en la nube',
            description: 'Nunca pierdas tu progreso',
          ),
          _buildBenefitItem(
            icon: Icons.leaderboard,
            title: 'Rankings globales',
            description: 'Compite con jugadores de todo el mundo',
          ),
          _buildBenefitItem(
            icon: Icons.sync,
            title: 'Sincronización',
            description: 'Juega en múltiples dispositivos',
          ),
          _buildBenefitItem(
            icon: Icons.emoji_events,
            title: 'Logros permanentes',
            description: 'Desbloquea achievements únicos',
          ),
        ],
      ),
    );
  }

  // 🎯 Item de beneficio
  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.deepPurple.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔐 Botones de login
  Widget _buildLoginButtons() {
    return Column(
      children: [
        // 📘 Botón de Facebook
        _buildSocialLoginButton(
          onPressed: _loginWithFacebook,
          backgroundColor: const Color(0xFF1877F2),
          icon: Icons.facebook,
          text: 'Continuar con Facebook',
        ),
        
        const SizedBox(height: 16),
        
        // 🔍 Botón de Google
        _buildSocialLoginButton(
          onPressed: _loginWithGoogle,
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          icon: Icons.g_mobiledata,
          text: 'Continuar con Google',
          borderColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  // 📱 Botón de login social
  Widget _buildSocialLoginButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String text,
    Color textColor = Colors.white,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: borderColor != null 
                ? BorderSide(color: borderColor, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👤 Opción de continuar como invitado
  Widget _buildGuestOption() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
          ],
        ),
        
        const SizedBox(height: 16),
        
        TextButton(
          onPressed: _continueAsGuest,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Continuar como invitado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Podrás registrarte más tarde desde configuraciones',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}