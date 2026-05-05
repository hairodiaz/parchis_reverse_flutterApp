import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart'; // 🎮 Import para ParchisBoard
import '../services/auth_service.dart';
import '../services/audio_service.dart';

/// 🌐 PANTALLA DE BÚSQUEDA ONLINE SIMULADA
/// 
/// Esta pantalla simula la búsqueda de jugadores en línea.
/// Los "jugadores encontrados" son en realidad CPUs de IA.
/// 
/// Flujo:
/// 1. Usuario ingresa nickname y selecciona color
/// 2. Toca "BUSCAR JUGADORES"
/// 3. Animación de carga (3-5 segundos)
/// 4. "¡Jugadores encontrados!"
/// 5. Navega a ParchisBoard con 3 CPUs

class OnlineMatchmakingScreen extends StatefulWidget {
  const OnlineMatchmakingScreen({super.key});

  @override
  State<OnlineMatchmakingScreen> createState() =>
      _OnlineMatchmakingScreenState();
}

class _OnlineMatchmakingScreenState extends State<OnlineMatchmakingScreen>
    with TickerProviderStateMixin {
  // 🎮 Controladores de animación
  late AnimationController _pulseController;
  late AnimationController _matchmakingController;
  late Animation<double> _pulseAnimation;

  // 📊 Estado
  final TextEditingController _nicknameController = TextEditingController();
  String _selectedColor = 'red';
  int _selectedPlayerCount = 4; // 🎮 Cantidad de jugadores (2, 3 o 4)
  bool _isSearching = false;
  int _foundPlayersCount = 0;

  // 🎨 Colores disponibles
  final List<Color> _playerColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];

  final List<String> _colorNames = ['Rojo', 'Azul', 'Verde', 'Amarillo'];

  @override
  void initState() {
    super.initState();

    // 🎨 Inicializar animación de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 🎮 Inicializar controlador de matchmaking
    _matchmakingController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // 📝 Cargar nickname del usuario
    _initializeNickname();
  }

  void _initializeNickname() {
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      _nicknameController.text = currentUser.name;
    } else {
      _nicknameController.text = 'Jugador ${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
  }

  Future<void> _startMatchmaking() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un nickname'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);
    _foundPlayersCount = 0;

    // 🔊 Reproducir sonido de búsqueda
    try {
      await AudioService().playDiceRoll();
    } catch (e) {
      print('⚠️ Error reproduciendo sonido: $e');
    }

    // 📡 SIMULACIÓN DE BÚSQUEDA - Dinámicamente según cantidad seleccionada
    int cpuCount = _selectedPlayerCount - 1; // Menos el usuario
    
    // Mostrar CPUs encontrados progresivamente
    for (int i = 1; i <= cpuCount; i++) {
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
        if (mounted) {
          setState(() => _foundPlayersCount = i);
          
          if (i == 1) {
            _showFoundMessage('¡$i jugador encontrado! 👥');
          } else if (i < cpuCount) {
            _showFoundMessage('¡$i jugadores encontrados! 👥');
          } else {
            // Último mensaje
            _showFoundMessage('¡$i jugadores encontrados! ¡Iniciando partida! 🎮');
          }
        }
      });
    }

    // ⏱️ Esperar 1 segundo antes de navegar
    await Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        // 🔇 Detener música de fondo
        await AudioService().stopBackgroundMusic();
        print('🔇 Música de fondo detenida');

        // 🚀 Navegar al juego
        if (mounted) {
          _navigateToGame();
        }
      }
    });
  }

  void _showFoundMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _navigateToGame() {
    // 📋 Obtener índice del color seleccionado
    int colorIndex = _colorNames.indexOf(_selectedColor);
    if (colorIndex == -1) colorIndex = 0;

    // 🎮 Crear lista de nombres y tipos de jugadores dinámicamente
    List<String> playerNames = [_nicknameController.text];
    List<bool> isHuman = [true];
    
    // Agregar CPUs según la cantidad seleccionada
    for (int i = 1; i < _selectedPlayerCount; i++) {
      playerNames.add('CPU $i');
      isHuman.add(false);
    }

    // 🎨 Asignar colores: el usuario toma su color seleccionado,
    // y los CPUs toman los otros colores de forma rotativa
    List<int> playerColorIndices = [colorIndex];
    for (int i = 1; i < _selectedPlayerCount; i++) {
      int nextColor = (colorIndex + i) % 4;
      playerColorIndices.add(nextColor);
    }

    // 🎲 Orden aleatorio de turnos (solo para los jugadores que existen)
    List<int> turnOrder = List.generate(_selectedPlayerCount, (i) => i);
    turnOrder.shuffle();

    // 🚀 Navegar a ParchisBoard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ParchisBoard(
          numPlayers: _selectedPlayerCount,
          playerNames: playerNames,
          isHuman: isHuman,
          playerColorIndices: playerColorIndices,
          turnOrder: turnOrder,
          isOnlineMode: true, // 🌐 Marcar como modo online simulado
          onlinePlayerIndex: 0, // 🎮 El usuario es siempre el Jugador 0
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _matchmakingController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🌐 JUGAR ONLINE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        leading: IconButton(
          onPressed: _isSearching ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🎮 TÍTULO Y DESCRIPCIÓN
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.public,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'BÚSQUEDA EN LÍNEA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige tu cantidad de jugadores y juega en línea',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 📝 CAMPO DE NICKNAME
                if (!_isSearching) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                        // Campo de texto
                        TextField(
                          controller: _nicknameController,
                          enabled: !_isSearching,
                          maxLength: 15,
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu apodo',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFF1976D2),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFF1976D2),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFF0D47A1),
                                width: 3,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.account_circle,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Selector de cantidad de jugadores
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '👥 ¿Cuántos jugadores?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (int players in [2, 3, 4])
                                  FilterChip(
                                    label: Text(
                                      '$players',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedPlayerCount == players
                                            ? Colors.white
                                            : const Color(0xFF1976D2),
                                      ),
                                    ),
                                    selected: _selectedPlayerCount == players,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedPlayerCount = players;
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: const Color(0xFF1976D2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: _selectedPlayerCount == players
                                            ? const Color(0xFF1976D2)
                                            : Colors.grey[300]!,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Selector de color
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🎨 Elige tu color',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                _playerColors.length,
                                (index) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedColor = _colorNames[index];
                                    });
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: _playerColors[index],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _selectedColor ==
                                                _colorNames[index]
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _playerColors[index]
                                              .withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _selectedColor ==
                                            _colorNames[index]
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 28,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🔘 BOTÓN BUSCAR
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1976D2),
                          Color(0xFF0D47A1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _startMatchmaking,
                        borderRadius: BorderRadius.circular(15),
                        child: const Center(
                          child: Text(
                            '🔍 BUSCAR JUGADORES',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // 📡 PANTALLA DE BÚSQUEDA
                if (_isSearching) ...[
                  const SizedBox(height: 60),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.radar,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Buscando jugadores...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 📊 Contador de jugadores encontrados
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Jugadores encontrados:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_foundPlayersCount/${_selectedPlayerCount - 1}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Barras de progreso (dinámicas según cantidad seleccionada)
                        Row(
                          children: List.generate(
                            _selectedPlayerCount - 1,
                            (index) => Expanded(
                              child: Container(
                                height: 6,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: index < _foundPlayersCount
                                      ? Colors.green
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 📝 Información
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '💡 Los jugadores en línea pueden unirse a tu partida. '
                      'Se asignarán aleatoriamente.\n\n'
                      '⏱️ Tiempo máximo de espera: 30 segundos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
