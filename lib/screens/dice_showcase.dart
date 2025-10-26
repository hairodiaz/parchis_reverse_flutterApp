import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class DiceShowcase extends StatelessWidget {
  const DiceShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Dado 3D',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Dice3D(),
      ),
    );
  }
}

class Dice3D extends StatefulWidget {
  const Dice3D({super.key});
  @override
  State<Dice3D> createState() => _Dice3DState();
}

class _Dice3DState extends State<Dice3D> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _resultController;
  late final AudioPlayer _audioPlayer;
  final Random _random = Random();
  int _finalValue = 1; // Valor inicial
  Timer? _rerollTimer;
  bool _showRerollButton = false;
  bool _isAnimating = false;
  
  // Variables para rotaciones aleatorias
  double _randomRotationX = 0;
  double _randomRotationY = 0;
  double _randomRotationZ = 0;
  
  // Variables para la parada natural
  double _finalRotationX = 0;
  double _finalRotationY = 0;
  double _finalRotationZ = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _resultController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _audioPlayer = AudioPlayer();
    _generateRandomRotations(); // Inicializar rotaciones aleatorias
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _resultController.dispose();
    _rerollTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _generateRandomRotations() {
    // Rotaciones más naturales y suaves (reducidas significativamente)
    _randomRotationX = 1.5 + _random.nextDouble() * 2; // Entre 1.5 y 3.5 rotaciones
    _randomRotationY = 2 + _random.nextDouble() * 3;   // Entre 2 y 5 rotaciones  
    _randomRotationZ = 0.5 + _random.nextDouble() * 1.5; // Entre 0.5 y 2 rotaciones
    
    // AHORA SÍ calcular posición final porque ya tenemos _finalValue
    _calculateFinalPosition();
  }
  
  void _calculateFinalPosition() {
    // MAPEO CORREGIDO BASADO EN LA CONSTRUCCIÓN REAL DEL CUBO:
    // Cara frontal (1) está en Z=50 sin rotación inicial
    // Cara trasera (6) está rotada 180° en Y desde la frontal  
    // Cara derecha (2) está rotada 90° en Y desde la frontal
    // Cara izquierda (5) está rotada -90° en Y desde la frontal
    // Cara inferior (3) está rotada 90° en X desde la frontal
    // Cara superior (4) está rotada -90° en X desde la frontal
    
    // Para MOSTRAR cada cara, necesito aplicar la rotación OPUESTA:
    switch (_finalValue) {
      case 1: // Para mostrar cara frontal (1) - sin rotación
        _finalRotationX = 0;
        _finalRotationY = 0;
        _finalRotationZ = 0;
        break;
      case 2: // Para mostrar cara derecha (2) - rotar IZQUIERDA para traerla al frente
        _finalRotationX = 0;
        _finalRotationY = -pi/2; // Rotación opuesta a la construcción
        _finalRotationZ = 0;
        break;
      case 3: // Para mostrar cara inferior (3) - rotar ARRIBA para traerla al frente
        _finalRotationX = -pi/2; // Rotación opuesta a la construcción  
        _finalRotationY = 0;
        _finalRotationZ = 0;
        break;
      case 4: // Para mostrar cara superior (4) - rotar ABAJO para traerla al frente
        _finalRotationX = pi/2; // Rotación opuesta a la construcción
        _finalRotationY = 0;
        _finalRotationZ = 0;
        break;
      case 5: // Para mostrar cara izquierda (5) - rotar DERECHA para traerla al frente
        _finalRotationX = 0;
        _finalRotationY = pi/2; // Rotación opuesta a la construcción
        _finalRotationZ = 0;
        break;
      case 6: // Para mostrar cara trasera (6) - rotar 180° para traerla al frente
        _finalRotationX = 0;
        _finalRotationY = pi; // Mismo que la construcción para traer trasera al frente
        _finalRotationZ = 0;
        break;
    }
    print('MAPEO FINAL CORREGIDO - Valor: $_finalValue -> RotX: ${_finalRotationX*180/pi}°, RotY: ${_finalRotationY*180/pi}°');
  }

  void _roll() async {
    setState(() {
      _isAnimating = true;
      _showRerollButton = false;
      // Generar el resultado AHORA para calcular hacia dónde debe ir
      _finalValue = _random.nextInt(6) + 1;
    });
    
    // Cancelar timer anterior si existe
    _rerollTimer?.cancel();
    
    // Generar rotaciones aleatorias Y calcular posición final
    _generateRandomRotations();
    
    // Reproducir sonido del dado
    try {
      await _audioPlayer.play(AssetSource('audio/effects/Dice.mp3'));
    } catch (e) {
      print('Error al reproducir sonido: $e');
    }
    
    // Iniciar animación
    _ctrl.reset();
    _ctrl.duration = const Duration(milliseconds: 2500);
    
    // Cuando termine la animación, mostrar resultado
    _ctrl.forward().then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _showRerollButton = true;
        });
        _showFinalResult();
        _startRerollTimer();
      }
    });
  }

  // Eliminar _determineActualResult - ya no se necesita

  void _showFinalResult() {
    _resultController.reset();
    _resultController.forward();
  }

  void _startRerollTimer() {
    // Timer de 3 segundos para ocultar el botón de relanzar
    _rerollTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showRerollButton = false;
        });
      }
    });
  }

  // Función para interpolar rotaciones con transición más suave
  double _lerpRotation(double start, double peak, double end, double t) {
    // Asegurar que t esté siempre en rango [0, 1]
    t = t.clamp(0.0, 1.0);
    
    if (t < 0.75) {
      // Primera fase: rotación intensa (0 -> peak) - 75% del tiempo
      return start + (peak - start) * (t / 0.75);
    } else {
      // Segunda fase: transición suave hacia la posición final - 25% del tiempo
      final double finalPhase = (t - 0.75) / 0.25;
      
      // Usar una función de suavizado que empiece rápido y termine muy suave
      final double smoothFactor = finalPhase * finalPhase * (3.0 - 2.0 * finalPhase);
      
      return peak + (end - peak) * smoothFactor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'CUBO 3D REALISTA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 20),
        // Mostrar resultado SOLO cuando esté en posición final
        AnimatedBuilder(
          animation: _resultController,
          builder: (context, child) {
            // Solo mostrar cuando el botón de relanzar esté activo Y la animación principal haya terminado
            final double opacity = (_showRerollButton && !_isAnimating) ? _resultController.value : 0.0;
            final double scale = 0.8 + (_resultController.value * 0.2);
            
            return AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 300),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Text(
                    'Resultado: $_finalValue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return _build3DCube(_ctrl.value);
            },
          ),
        ),
        const SizedBox(height: 30),
        // Botones dinámicos según el estado
        if (!_isAnimating && !_showRerollButton)
          // Botón inicial de lanzar dado
          ElevatedButton(
            onPressed: _roll,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('Lanzar Dado', style: TextStyle(fontSize: 16)),
          ),
        
        if (_showRerollButton)
          // Botón de relanzar (aparece por 3 segundos)
          AnimatedOpacity(
            opacity: _showRerollButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: _roll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Relanzar Dado', style: TextStyle(fontSize: 16)),
            ),
          ),
      ],
    );
  }

  Widget _build3DCube(double t) {
    // Asegurar que t esté en rango seguro y NO usar curves problemáticas
    t = t.clamp(0.0, 1.0);
    
    // Calcular rotaciones con transición suave a la posición final
    final double rotationX = _lerpRotation(0, _randomRotationX * pi, _finalRotationX, t);
    final double rotationY = _lerpRotation(0, _randomRotationY * pi, _finalRotationY, t);
    final double rotationZ = _lerpRotation(0, _randomRotationZ * pi, _finalRotationZ, t);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspectiva más sutil para cubo perfecto
        ..rotateX(rotationX)
        ..rotateY(rotationY)
        ..rotateZ(rotationZ),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          children: [
            // Caras del cubo corregidas para coincidir con las rotaciones finales
            
            // Cara frontal (1) - Sin rotación
            _buildFace(1, Colors.white, Matrix4.identity()..translate(0.0, 0.0, 50.0)),
            
            // Cara trasera (6) - Rotación Y = 180°
            _buildFace(6, Colors.white, Matrix4.identity()
              ..rotateY(pi)
              ..translate(0.0, 0.0, 50.0)),
            
            // Cara derecha (2) - Rotación Y = 90°
            _buildFace(2, Colors.white, Matrix4.identity()
              ..rotateY(pi/2)
              ..translate(0.0, 0.0, 50.0)),
            
            // Cara izquierda (5) - Rotación Y = -90°
            _buildFace(5, Colors.white, Matrix4.identity()
              ..rotateY(-pi/2)
              ..translate(0.0, 0.0, 50.0)),
            
            // Cara inferior (3) - Rotación X = 90°
            _buildFace(3, Colors.white, Matrix4.identity()
              ..rotateX(pi/2)
              ..translate(0.0, 0.0, 50.0)),
            
            // Cara superior (4) - Rotación X = -90°
            _buildFace(4, Colors.white, Matrix4.identity()
              ..rotateX(-pi/2)
              ..translate(0.0, 0.0, 50.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildFace(int value, Color color, Matrix4 transform) {
    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 1.5), // Borde más sutil
          borderRadius: BorderRadius.circular(6), // Bordes menos redondeados para cubo más perfecto
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Sombra más sutil
              blurRadius: 2,
              offset: const Offset(1, 1), // Sombra más pequeña
            ),
          ],
        ),
        child: _buildDiceDots(value),
      ),
    );
  }

  Widget _buildDiceDots(int value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDotRow(value, 0),
          _buildDotRow(value, 1),
          _buildDotRow(value, 2),
        ],
      ),
    );
  }

  Widget _buildDotRow(int value, int row) {
    final pattern = _getDotPattern(value);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDot(pattern[row * 3]),
        _buildDot(pattern[row * 3 + 1]),
        _buildDot(pattern[row * 3 + 2]),
      ],
    );
  }

  Widget _buildDot(bool visible) {
    return Container(
      width: 14, // Puntos un poco más pequeños para mejor proporción
      height: 14,
      decoration: BoxDecoration(
        color: visible ? Colors.black : Colors.transparent,
        shape: BoxShape.circle,
      ),
    );
  }

  List<bool> _getDotPattern(int value) {
    switch (value) {
      case 1:
        return [false, false, false, false, true, false, false, false, false];
      case 2:
        return [true, false, false, false, false, false, false, false, true];
      case 3:
        return [true, false, false, false, true, false, false, false, true];
      case 4:
        return [true, false, true, false, false, false, true, false, true];
      case 5:
        return [true, false, true, false, true, false, true, false, true];
      case 6:
        return [true, false, true, true, false, true, true, false, true];
      default:
        return [false, false, false, false, true, false, false, false, false];
    }
  }
}