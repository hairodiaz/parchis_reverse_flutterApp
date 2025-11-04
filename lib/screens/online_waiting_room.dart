import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart'; // 🎮 Import para acceder a ParchisBoard

/// 🏠 PANTALLA DE SALA DE ESPERA ONLINE
/// 
/// Esta pantalla muestra:
/// - 👥 Lista de jugadores conectados
/// - 🎮 Botón para iniciar partida (solo anfitrión)
/// - 📋 Código de sala para compartir
/// - 🚪 Opción para salir de la sala

class OnlineWaitingRoom extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final Color playerColor;
  final bool isHost;

  const OnlineWaitingRoom({
    Key? key,
    required this.roomCode,
    required this.playerName,
    required this.playerColor,
    required this.isHost,
  }) : super(key: key);

  @override
  State<OnlineWaitingRoom> createState() => _OnlineWaitingRoomState();
}

class _OnlineWaitingRoomState extends State<OnlineWaitingRoom> 
    with TickerProviderStateMixin {
  
  // 🎨 Controladores de animación
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // 📊 Estado
  List<Map<String, dynamic>> connectedPlayers = [];
  bool isGameStarting = false;

  @override
  void initState() {
    super.initState();
    
    // 🎨 Inicializar animaciones
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    // 🚀 Inicializar sala
    _initializeRoom();
    _slideController.forward();
  }

  void _initializeRoom() {
    // 🎮 Agregar solo el jugador actual a la lista
    connectedPlayers.add({
      'name': widget.playerName,
      'color': widget.playerColor,
      'isHost': widget.isHost,
      'isReady': true,
      'connectionTime': DateTime.now(),
    });
    
    // 🔥 MODO REAL: Sin jugadores fantasmas
    // Los jugadores reales se unirán vía WebSocket
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
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
              Color(0xFF1A237E),
              Color(0xFF3949AB),
              Color(0xFF5C6BC0),
            ],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildPlayersList()),
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 📱 Header con botón de volver y código de sala
          Row(
            children: [
              IconButton(
                onPressed: () => _showExitDialog(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _copyRoomCodeToClipboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.content_copy, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.roomCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance para centrar
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 📡 Icono de conexión animado
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.2),
                    border: Border.all(color: Colors.green.withOpacity(0.4), width: 3),
                  ),
                  child: const Icon(
                    Icons.wifi,
                    color: Colors.green,
                    size: 35,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 15),
          
          // 🎮 Título y estado
          const Text(
            '🏠 Sala de Espera',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Jugadores conectados: ${connectedPlayers.length}/4',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 5),
          
          Text(
            'Toca el código para copiarlo',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 4, // Máximo 4 jugadores
              itemBuilder: (context, index) {
                if (index < connectedPlayers.length) {
                  return _buildPlayerCard(connectedPlayers[index], index);
                } else {
                  return _buildEmptySlot(index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, int index) {
    final isCurrentPlayer = player['name'] == widget.playerName;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrentPlayer 
            ? Colors.white.withOpacity(0.98)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: isCurrentPlayer 
            ? Border.all(color: Colors.blue, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCurrentPlayer 
                ? Colors.blue.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: isCurrentPlayer ? 15 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🎨 Avatar del jugador
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: player['color'],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (player['color'] as Color).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 15),
          
          // 📋 Info del jugador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentPlayer) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TÚ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (player['isHost']) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ANFITRIÓN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      player['isReady'] ? Icons.check_circle : Icons.access_time,
                      color: player['isReady'] ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      player['isReady'] ? 'Listo para jugar' : 'Preparándose...',
                      style: TextStyle(
                        color: player['isReady'] ? Colors.green : Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ✅ Estado del jugador
          if (player['isReady'])
            const Icon(
              Icons.verified,
              color: Colors.green,
              size: 28,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: const Icon(
              Icons.person_add,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esperando jugador ${index + 1}...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Comparte el código de sala',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
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

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 🎮 Botón de iniciar partida (solo anfitrión)
          if (widget.isHost && connectedPlayers.length >= 2) ...[
            Container(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isGameStarting ? null : _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 8,
                ),
                child: isGameStarting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Iniciando partida...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    : const Text(
                        '🎮 INICIAR PARTIDA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 15),
          ],
          
          // 📋 Info para el anfitrión
          if (widget.isHost && connectedPlayers.length < 2) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Necesitas al menos 2 jugadores para iniciar',
                      style: TextStyle(
                        color: Colors.orange.shade100,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
          ],
          
          // 🚪 Botón de salir
          Container(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => _showExitDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                widget.isHost ? 'Cerrar Sala' : 'Salir de la Sala',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📋 COPIAR CÓDIGO DE SALA
  void _copyRoomCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Código ${widget.roomCode} copiado al portapapeles'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🎮 INICIAR PARTIDA
  void _startGame() {
    setState(() {
      isGameStarting = true;
    });

    // Simular proceso de inicio
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showStartGameDialog();
      }
    });
  }

  // 🎯 DIÁLOGO DE INICIO DE PARTIDA
  void _showStartGameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sports_esports, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('¡Partida Lista!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎮 ${connectedPlayers.length} jugadores conectados'),
            const SizedBox(height: 10),
            const Text('¿Estás listo para iniciar el Parchís online?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              setState(() => isGameStarting = false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              _navigateToOnlineGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('¡JUGAR!'),
          ),
        ],
      ),
    );
  }

  // 🎮 NAVEGAR AL JUEGO ONLINE
  void _navigateToOnlineGame() {
    // 🎯 Preparar datos para modo online
    final onlinePlayerNames = <String>[];
    final onlineIsHuman = <bool>[];
    final onlineColorIndices = <int>[];
    
    // 📋 Convertir jugadores conectados a formato de ParchisBoard
    for (int i = 0; i < connectedPlayers.length && i < 4; i++) {
      final player = connectedPlayers[i];
      onlinePlayerNames.add(player['name']);
      onlineIsHuman.add(true); // Todos son humanos en modo online
      
      // 🎨 Convertir color a índice
      Color playerColor = player['color'];
      int colorIndex = 0; // Default rojo
      if (playerColor == Colors.blue) colorIndex = 1;
      else if (playerColor == Colors.green) colorIndex = 2;
      else if (playerColor == Colors.yellow) colorIndex = 3;
      
      onlineColorIndices.add(colorIndex);
    }
    
    // 🔥 NAVEGAR AL PARCHIS BOARD EN MODO ONLINE
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ParchisBoard(
          numPlayers: connectedPlayers.length,
          playerNames: onlinePlayerNames,
          isHuman: onlineIsHuman,
          playerColorIndices: onlineColorIndices,
          turnOrder: List.generate(connectedPlayers.length, (index) => index),
          // 🌐 PARÁMETROS DE MODO ONLINE
          isOnlineMode: true,
          roomCode: widget.roomCode,
          onlinePlayerIndex: 0, // Por ahora siempre el primer jugador (anfitrión)
        ),
      ),
    );
  }

  // 🚪 DIÁLOGO DE SALIR
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.isHost ? '¿Cerrar la sala?' : '¿Salir de la sala?'),
        content: Text(
          widget.isHost 
              ? 'Al cerrar la sala, todos los jugadores serán desconectados.'
              : '¿Estás seguro que quieres abandonar la sala de espera?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver al lobby
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(widget.isHost ? 'Cerrar Sala' : 'Salir'),
          ),
        ],
      ),
    );
  }
}