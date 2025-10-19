import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../main.dart';

/// 🎬 Pantalla de introducción con video
/// 
/// Esta pantalla reproduce automáticamente el video de intro del juego
/// y navega a la pantalla principal cuando termina.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  /// Inicializar y configurar el reproductor de video
  Future<void> _initializeVideo() async {
    try {
      // Cargar video desde assets
      _videoController = VideoPlayerController.asset('assets/video/parchis_intro.mp4');
      
      await _videoController.initialize();
      
      setState(() {
        _isVideoInitialized = true;
      });

      // 🎬 Reproducir automáticamente
      _videoController.play();

      // 📍 Listener para detectar cuando termine el video
      _videoController.addListener(_videoListener);
      
      print('🎬 Video de intro inicializado y reproduciéndose');
    } catch (e) {
      print('❌ Error inicializando video: $e');
      // Si hay error con el video, navegar inmediatamente
      _navigateToHome();
    }
  }

  /// Listener para detectar cuando el video termina
  void _videoListener() {
    if (_videoController.value.position >= _videoController.value.duration && 
        !_hasNavigated) {
      print('🎬 Video de intro terminado - Navegando a pantalla principal');
      _navigateToHome();
    }
  }

  /// Navegar a la pantalla principal
  void _navigateToHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainMenuScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // ✨ Transición suave con fade
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// Función para saltar el intro (tap en pantalla)
  void _skipIntro() {
    print('⏭️ Usuario saltó el intro');
    _navigateToHome();
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _skipIntro, // Permitir saltar el intro tocando la pantalla
        child: Stack(
          children: [
            // 🎬 REPRODUCTOR DE VIDEO
            if (_isVideoInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              )
            else
              // 🔄 Loading mientras se carga el video
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Cargando intro...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

            // 💡 INDICADOR DE "TOCA PARA SALTAR"
            if (_isVideoInitialized)
              Positioned(
                bottom: 40,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Toca para saltar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 🎮 LOGO DEL JUEGO (opcional, aparece al inicio)
            if (!_isVideoInitialized)
              const Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.casino,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'PARCHIS REVERSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
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
  }
}