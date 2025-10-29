import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DiceShowcase extends StatelessWidget {
  const DiceShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Dado 3D - Pruebas',
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
  late AnimationController _animationController;
  late Animation<double> _rotationX;
  late Animation<double> _rotationY;
  late Animation<double> _rotationZ;
  
  final Random _random = Random();
  int _finalValue = 1;
  bool _isRolling = false;
  
  // Rotaciones finales para cada cara (PiliApp style)
  final Map<int, List<double>> _finalRotations = {
    1: [0, 0, 0],                    // Frontal
    2: [0, -pi/2, 0],               // Derecha al frente
    3: [-pi/2, 0, 0],               // Superior al frente
    4: [pi/2, 0, 0],                // Inferior al frente
    5: [0, pi/2, 0],                // Izquierda al frente
    6: [0, pi, 0],                  // Trasera al frente
  };
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRolling = false;
        });
      }
    });
  }
  
  void _setupRotations() {
    final List<double> finalRot = _finalRotations[_finalValue]!;
    
    // Múltiples vueltas + posición final exacta
    final double totalX = (_random.nextDouble() * 6 + 4) * 2 * pi + finalRot[0];
    final double totalY = (_random.nextDouble() * 6 + 4) * 2 * pi + finalRot[1];
    final double totalZ = (_random.nextDouble() * 4 + 2) * 2 * pi + finalRot[2];
    
    _rotationX = Tween<double>(
      begin: 0,
      end: totalX,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _rotationY = Tween<double>(
      begin: 0,
      end: totalY,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _rotationZ = Tween<double>(
      begin: 0,
      end: totalZ,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  void _rollDice() {
    if (_isRolling) return;
    
    setState(() {
      _isRolling = true;
      _finalValue = _random.nextInt(6) + 1;
    });
    
    _setupRotations();
    _animationController.reset();
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cubo 3D
        SizedBox(
          width: 200,
          height: 200,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_rotationX.value)
                  ..rotateY(_rotationY.value)
                  ..rotateZ(_rotationZ.value),
                child: _buildCube(),
              );
            },
          ),
        ),
        
        const SizedBox(height: 40),
        
        Text(
          'Resultado: $_finalValue',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 30),
        
        ElevatedButton(
          onPressed: _isRolling ? null : _rollDice,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRolling ? Colors.grey : Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text(
            _isRolling ? 'Lanzando...' : 'Lanzar Dado',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCube() {
    return Stack(
      children: [
        // Cara frontal (1)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..translate(0.0, 0.0, 50.0),
          child: _buildFace(1),
        ),
        // Cara trasera (6)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(0.0, 0.0, -50.0)
            ..rotateY(pi),
          child: _buildFace(6),
        ),
        // Cara derecha (2)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(50.0, 0.0, 0.0)
            ..rotateY(pi / 2),
          child: _buildFace(2),
        ),
        // Cara izquierda (5)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(-50.0, 0.0, 0.0)
            ..rotateY(-pi / 2),
          child: _buildFace(5),
        ),
        // Cara superior (3)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(0.0, -50.0, 0.0)
            ..rotateX(-pi / 2),
          child: _buildFace(3),
        ),
        // Cara inferior (4)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(0.0, 50.0, 0.0)
            ..rotateX(pi / 2),
          child: _buildFace(4),
        ),
      ],
    );
  }
  
  Widget _buildFace(int number) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: _buildDots(number),
    );
  }
  
  Widget _buildDots(int number) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _getDotsLayout(number),
    );
  }
  
  Widget _getDotsLayout(int number) {
    switch (number) {
      case 1:
        return Center(child: _dot());
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.topLeft, child: _dot()),
            Align(alignment: Alignment.bottomRight, child: _dot()),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.topLeft, child: _dot()),
            Center(child: _dot()),
            Align(alignment: Alignment.bottomRight, child: _dot()),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(), _dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(), _dot()],
            ),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(), _dot()],
            ),
            Center(child: _dot()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(), _dot()],
            ),
          ],
        );
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(), _dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(), _dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(), _dot()],
            ),
          ],
        );
      default:
        return Center(child: _dot());
    }
  }
  
  Widget _dot() {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}