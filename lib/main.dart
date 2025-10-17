import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

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
      home: const SplashScreen(), // Comenzar con la pantalla de carga
      debugShowCheckedModeBanner: false,
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
    
    // Esperar y navegar a configuración
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PlayerConfigScreen()),
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
  Widget build(BuildContext context) {
    return Scaffold(
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
                                    decoration: InputDecoration(
                                      hintText: 'Nombre del jugador',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        playerNames[index] = value.isEmpty 
                                            ? 'Jugador ${index + 1}' 
                                            : value;
                                      });
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
  bool isMoving = false; // Para bloquear el dado mientras se mueve una ficha
  GamePiece? jumpingPiece; // Para saber qué ficha está saltando
  
  // Variables para mensajes jocosos
  String? lastMessage;
  Timer? _messageTimer;
  String currentMessage = ''; // Para mensajes de casillas especiales
  
  // Ruta de movimiento en el tablero (secuencia de posiciones)
  List<Position> boardPath = [];

  @override
  void initState() {
    super.initState();
    
    // Configurar jugadores según la pantalla de configuración
    for (int i = 0; i < widget.numPlayers; i++) {
      customPlayerNames[i] = widget.playerNames[i];
    }
    
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
    gamePieces = [
      GamePiece(id: '1', color: Colors.red, position: salidaPosition),
      GamePiece(id: '2', color: Colors.blue, position: salidaPosition),
      GamePiece(id: '3', color: Colors.green, position: salidaPosition),
      GamePiece(id: '4', color: Colors.yellow, position: salidaPosition),
    ];
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
    
    // ¡SONIDO DEL DADO! 🎵
    _playDiceSound();
    
    _animationController.reset();
    _animationController.forward();
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        diceValue = random.nextInt(6) + 1;
      });
    });

    Timer(const Duration(milliseconds: 800), () {
      _timer?.cancel();
      setState(() {
        diceValue = random.nextInt(6) + 1;
        isMoving = true; // Bloquear el dado
      });
      
      // Verificar amenaza DESPUÉS de la animación del dado, ANTES del movimiento
      Timer(const Duration(milliseconds: 200), () {
        bool hasThreats = _checkAndShowThreatMessage(diceValue);
        
        if (hasThreats) {
          // Si hay amenaza: esperar MÁS TIEMPO para el mensaje, luego QUITARLO antes del movimiento
          Timer(const Duration(milliseconds: 1500), () {
            // Quitar el mensaje de amenaza antes del movimiento
            setState(() {
              lastMessage = null;
            });
            
            // Pequeña pausa después de quitar el mensaje, luego mover
            Timer(const Duration(milliseconds: 300), () {
              _moveCurrentPlayerPiece(diceValue);
            });
          });
        } else {
          // Si NO hay amenaza: mover rápidamente
          Timer(const Duration(milliseconds: 400), () {
            _moveCurrentPlayerPiece(diceValue);
          });
        }
      });
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

    // Cambiar al siguiente jugador y desbloquear el dado después de completar el movimiento
    setState(() {
      if (shouldChangeTurn) {
        currentPlayerIndex = (currentPlayerIndex + 1) % 4;
      }
      isMoving = false; // Desbloquear el dado
      jumpingPiece = null; // Ya no hay ficha saltando
    });
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

  // Construir el indicador de jugador para las esquinas
  Widget _buildPlayerIndicator(int playerIndex) {
    bool isCurrentPlayer = currentPlayerIndex == playerIndex;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPlayer 
            ? (playerColors[playerIndex] == Colors.yellow 
               ? Colors.orange.shade700  // Borde más oscuro para amarillo
               : playerColors[playerIndex])
            : Colors.white.withOpacity(0.5),
          width: isCurrentPlayer ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
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
          // Nombre del jugador
          Text(
            _getPlayerName(playerIndex),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.w500,
              color: isCurrentPlayer 
                ? (playerColors[playerIndex] == Colors.yellow 
                   ? Colors.orange.shade700  // Amarillo más oscuro para mejor contraste
                   : playerColors[playerIndex])
                : Colors.white,
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
        title: const Text(
          'Parchís Reverse Dominicano',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 4,
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
                // Área del tablero optimizada para móviles
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calcular padding basado en el tamaño de pantalla
                      double screenWidth = constraints.maxWidth;
                      double optimalPadding = screenWidth * 0.03; // 3% del ancho de pantalla
                      
                      return Padding(
                        padding: EdgeInsets.all(optimalPadding),
                        child: Stack(
                          children: [
                            // El tablero con proporciones fijas para móviles
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.02), // 2% del ancho
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
                                    padding: EdgeInsets.all(screenWidth * 0.015), // 1.5% del ancho
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: _buildBoard(),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Indicadores con posición más cerca del tablero
                            // Jugador 1 (Rojo) - Esquina superior izquierda
                            Positioned(
                              top: optimalPadding * 0.2, // Reducido de 0.3 a 0.2
                              left: optimalPadding * 0.2,
                              child: _buildPlayerIndicator(0),
                            ),

                            // Jugador 2 (Azul) - Esquina superior derecha
                            Positioned(
                              top: optimalPadding * 0.2,
                              right: optimalPadding * 0.2,
                              child: _buildPlayerIndicator(1),
                            ),

                            // Jugador 3 (Verde) - Esquina inferior izquierda
                            Positioned(
                              bottom: optimalPadding * 0.2,
                              left: optimalPadding * 0.2,
                              child: _buildPlayerIndicator(2),
                            ),

                            // Jugador 4 (Amarillo) - Esquina inferior derecha
                            Positioned(
                              bottom: optimalPadding * 0.2,
                              right: optimalPadding * 0.2,
                              child: _buildPlayerIndicator(3),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Sección del dado - proporción móvil
                LayoutBuilder(
                  builder: (context, constraints) {
                    double screenWidth = MediaQuery.of(context).size.width;
                    return Container(
                      margin: EdgeInsets.all(screenWidth * 0.02), // Reducido de 0.03 a 0.02 para subir el dado
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Lanzar Dado',
                                style: TextStyle(
                                  fontSize: 24, // Aumentado de 18 a 24
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _rollDice,
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _rotationAnimation.value,
                                      child: Transform.scale(
                                        scale: _scaleAnimation.value,
                                        child: _buildDice(diceValue),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
          padding: const EdgeInsets.all(10.0), // Aumentado de 9 a 10 para fichas solas un poquito más pequeñas
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