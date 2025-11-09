import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart'; // 🎮 Import para acceder a ParchisBoard
import '../websocket_service.dart'; // 🌐 Import para WebSocket
import '../models/online_game_models.dart'; // 📊 Import para modelos

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
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.playerColor,
    required this.isHost,
  });

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
  
  // 🌐 WebSocket y streams
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  OnlineGameRoom? _currentRoom;

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
    _setupWebSocketListeners();
    
    // Para clientes (no anfitriones), solicitar lista después de conectar
    if (!widget.isHost) {
      Future.delayed(Duration(milliseconds: 1000), () {
        _requestRoomPlayersList();
      });
    }
    
    _slideController.forward();
  }

  void _initializeRoom() {
    // 🎮 DEBUG: Verificar qué nombre estamos recibiendo
    print('🔍 DEBUG INICIALIZACIÓN:');
    print('   📝 widget.playerName: "${widget.playerName}"');
    print('   🎨 widget.playerColor: ${widget.playerColor}');
    print('   🏠 widget.isHost: ${widget.isHost}');
    print('   🔗 roomCode: ${widget.roomCode}');
    
    // SIEMPRE agregar el usuario actual primero
    connectedPlayers.add({
      'name': widget.playerName,
      'color': widget.playerColor,
      'isHost': widget.isHost,
      'isReady': true,
      'connectionTime': DateTime.now(),
      'id': _webSocketService.uniqueClientId ?? 'unknown',
    });
    
    if (widget.isHost) {
      print('🏠 Anfitrión inicializado: "${widget.playerName}"');
    } else {
      print('🔄 Cliente inicializado: "${widget.playerName}". Esperando otros jugadores...');
    }
  }

  /// 🌐 Configurar listeners de WebSocket para sincronización en tiempo real
  void _setupWebSocketListeners() {
    print('🔄 Configurando listeners WebSocket para sala: ${widget.roomCode}');
    
    _messageSubscription = _webSocketService.messageStream.listen((message) {
      print('📨📨📨 MENSAJE WEBSOCKET RECIBIDO 📨📨📨');
      print('🏷️ Tipo: ${message['type']}');
      print('🔍 Mensaje completo: $message');
      print('🎯 Mi sala actual: ${widget.roomCode}');
      print('🏠 ¿Soy anfitrión?: ${widget.isHost}');
      print('⏰ Timestamp: ${DateTime.now()}');
      
      switch (message['type']) {
        case 'room_updated':
          // Verificar si es un mensaje de inicio de juego disfrazado
          if (message['action'] == 'game_starting' || message['gameStarted'] == true) {
            print('🚀 Detectado inicio de juego via room_updated');
            _handleGameStart(message);
          } else {
            _handleRoomUpdate(message);
          }
          break;
        case 'player_joined':
          _handlePlayerJoined(message);
          break;
        case 'player_left':
          _handlePlayerLeft(message);
          break;
        case 'room_closed':
        case 'close_room':
        case 'room_destroyed':
        case 'room_ended':
          _handleRoomClosed(message);
          break;
        case 'host_left':
        case 'host_disconnected':
          _handleHostLeft(message);
          break;
        case 'room_players_list':
        case 'players_list':
          _handleRoomPlayersList(message);
          break;
        case 'start_game':
        case 'game_start':
          _handleGameStart(message);
          break;
        default:
          print('🤷 Tipo de mensaje no manejado: ${message['type']}');
          print('📋 Mensaje completo: $message');
      }
    });
  }

  /// 📋 Solicitar lista completa de jugadores en la sala
  void _requestRoomPlayersList() {
    print('📋 Solicitando lista de jugadores para sala: ${widget.roomCode}');
    
    // ESTRATEGIA TEMPORAL: Ya que el servidor no responde a get_room_players,
    // vamos a asumir que si no somos anfitrión, debe haber un anfitrión en la sala
    if (!widget.isHost) {
      print('🔄 Cliente detectando anfitrión en sala existente...');
      
      // Simular que "descubrimos" al anfitrión
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && connectedPlayers.length == 1) {
          setState(() {
            // Agregar un anfitrión genérico si no lo tenemos
            connectedPlayers.insert(0, {
              'name': 'Anfitrión de ${widget.roomCode}',
              'color': Colors.red,
              'isHost': true,
              'isReady': true,
              'connectionTime': DateTime.now().subtract(Duration(minutes: 1)),
              'id': 'host_${widget.roomCode}',
            });
          });
          print('✅ Anfitrión detectado y agregado a la lista');
        }
      });
    }
    
    // También intentar el mensaje real por si el servidor lo soporta en el futuro
    final message = {
      'type': 'get_room_players',
      'roomCode': widget.roomCode,
      'clientId': _webSocketService.uniqueClientId,
    };
    
    _webSocketService.sendMessage(message);
  }

  /// 🎨 Convertir string de color a Color object
  Color _colorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      default: return Colors.red;
    }
  }

  /// 📨 Manejar actualización de sala
  void _handleRoomUpdate(Map<String, dynamic> message) {
    print('🔄 Sala actualizada - usando eventos específicos');
    // Los cambios se manejan con eventos específicos como player_joined/player_left
  }

  /// 📋 Manejar lista completa de jugadores de la sala
  void _handleRoomPlayersList(Map<String, dynamic> message) {
    print('📋 DEBUG - Lista de jugadores recibida: $message');
    
    final playersData = message['players'] as List? ?? [];
    
    if (playersData.isNotEmpty) {
      _updatePlayersList(playersData);
    }
  }

  /// 👋 Manejar jugador que se une
  void _handlePlayerJoined(Map<String, dynamic> message) {
    print('👋 DEBUG - Mensaje player_joined completo: $message');
    
    // Verificar si el mensaje incluye una lista completa de jugadores
    final allPlayers = message['allPlayers'] ?? message['players'] ?? message['roomPlayers'];
    
    if (allPlayers != null) {
      // Si incluye lista completa, reemplazar toda la lista
      print('📋 Recibida lista completa de jugadores en player_joined');
      _updatePlayersList(allPlayers);
      return;
    }
    
    // Caso normal: solo un jugador nuevo
    // ⚠️ DEBUG: Imprimir todos los campos disponibles
    print('🔍 CAMPOS DISPONIBLES EN MENSAJE: ${message.keys.toList()}');
    for (final key in message.keys) {
      print('   $key: ${message[key]}');
    }
    
    // Intentar múltiples variaciones de nombres de campos
    String? playerName;
    String? playerId;
    
    // 🔍 Buscar nombre del jugador en diferentes campos
    final nameFields = ['playerName', 'name', 'player_name', 'player', 'username', 'nick', 'nickname'];
    for (final field in nameFields) {
      if (message[field] != null && message[field].toString().trim().isNotEmpty) {
        playerName = message[field].toString();
        print('✅ Nombre encontrado en campo "$field": "$playerName"');
        break;
      }
    }
    
    // 🔍 Buscar ID del jugador en diferentes campos  
    final idFields = ['clientId', 'playerId', 'id', 'client_id', 'player_id', 'userId'];
    for (final field in idFields) {
      if (message[field] != null && message[field].toString().trim().isNotEmpty) {
        playerId = message[field].toString();
        print('✅ ID encontrado en campo "$field": "$playerId"');
        break;
      }
    }
    
    // Fallbacks si no encontramos nada
    playerName ??= 'Jugador_${DateTime.now().millisecondsSinceEpoch % 10000}';
    playerId ??= 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    
    print('⚠️ Usando nombre final: "$playerName" (ID: "$playerId")');
                    
    final playerColor = message['playerColor'] ?? 
                       message['color'] ?? 
                       message['player_color'] ??
                       'red';
                       
    final isHost = message['isHost'] ?? 
                  message['is_host'] ?? 
                  false;
    
    print('👋 Jugador procesado: $playerName (ID: $playerId, Host: $isHost, Color: $playerColor)');
    
    if (mounted) {
      final currentUserId = _webSocketService.uniqueClientId;
      final playerExists = connectedPlayers.any((p) => 
        p['id'] == playerId || p['name'] == playerName);
      
      // Solo agregar si no es el usuario actual y no existe ya
      if (playerId != currentUserId && !playerExists) {
        setState(() {
          connectedPlayers.add({
            'name': playerName,
            'color': _colorFromString(playerColor),
            'isHost': isHost,
            'isReady': true,
            'connectionTime': DateTime.now(),
            'id': playerId,
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎮 $playerName se unió a la sala'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        print('✅ Jugador agregado. Total: ${connectedPlayers.length}');
      } else {
        print('🤷 Jugador ya existe o es el usuario actual - no agregado');
      }
    }
  }

  /// 📋 Actualizar lista completa de jugadores
  void _updatePlayersList(List<dynamic> playersData) {
    if (!mounted) return;
    
    setState(() {
      connectedPlayers.clear();
      
      // Siempre agregar primero nuestro usuario
      connectedPlayers.add({
        'name': widget.playerName,
        'color': widget.playerColor,
        'isHost': widget.isHost,
        'isReady': true,
        'connectionTime': DateTime.now(),
        'id': _webSocketService.uniqueClientId ?? 'me',
      });
      
      // Agregar otros jugadores
      final currentUserId = _webSocketService.uniqueClientId;
      
      for (final playerData in playersData) {
        final playerName = playerData['name'] ?? playerData['playerName'] ?? 'Jugador';
        final playerId = playerData['id'] ?? playerData['clientId'] ?? 'unknown';
        final playerColor = playerData['color'] ?? playerData['playerColor'] ?? 'red';
        final isHost = playerData['isHost'] ?? false;
        
        // Solo agregar si no es el usuario actual
        if (playerId != currentUserId && playerName != widget.playerName) {
          connectedPlayers.add({
            'name': playerName,
            'color': _colorFromString(playerColor),
            'isHost': isHost,
            'isReady': true,
            'connectionTime': DateTime.now(),
            'id': playerId,
          });
        }
      }
    });
    
    print('✅ Lista completa actualizada. Total: ${connectedPlayers.length}');
    for (final player in connectedPlayers) {
      print('   - ${player['name']} (Host: ${player['isHost']}, ID: ${player['id']})');
    }
  }

  /// 🚪 Manejar jugador que se va
  void _handlePlayerLeft(Map<String, dynamic> message) {
    final playerName = message['playerName'] ?? 'Desconocido';
    final playerId = message['clientId'] ?? message['playerId'] ?? 'unknown';
    
    print('🚪 Jugador se fue: $playerName (ID: $playerId)');
    
    if (mounted) {
      setState(() {
        connectedPlayers.removeWhere((player) => 
          player['id'] == playerId || player['name'] == playerName);
      });
      
      // Mostrar notificación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('👋 $playerName salió de la sala'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      
      print('✅ Jugador removido. Total restante: ${connectedPlayers.length}');
    }
  }

  /// 🔒 Manejar cierre de sala
  void _handleRoomClosed(Map<String, dynamic> message) {
    print('🔒 SALA CERRADA - Información completa:');
    print('   📨 Mensaje completo: $message');
    print('   🎯 Sala en mensaje: ${message['roomCode'] ?? message['room_code'] ?? message['room']}');
    print('   🏠 Mi sala actual: ${widget.roomCode}');
    print('   🆔 Mi ID: ${_webSocketService.uniqueClientId}');
    print('   👤 ¿Soy anfitrión?: ${widget.isHost}');
    
    // Verificar si el mensaje es para esta sala específica
    final messageRoom = message['roomCode'] ?? 
                       message['room_code'] ?? 
                       message['room'] ?? 
                       message['code'];
    
    if (messageRoom == null || messageRoom == widget.roomCode) {
      print('✅ Mensaje de cierre aplicable a esta sala - CERRANDO');
      
      if (mounted) {
        // Mostrar diálogo y volver al lobby
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('🔒 Sala Cerrada'),
            content: Text('El anfitrión cerró la sala. Serás redirigido al lobby.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver al lobby
                },
                child: Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } else {
      print('❌ Mensaje de cierre NO aplicable - sala diferente ($messageRoom vs ${widget.roomCode})');
    }
  }

  /// 👑 Manejar cuando el anfitrión se va
  void _handleHostLeft(Map<String, dynamic> message) {
    print('👑 El anfitrión abandonó la sala');
    
    if (mounted) {
      // Si no somos el anfitrión, la sala se cierra
      if (!widget.isHost) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('👑 Anfitrión Desconectado'),
            content: Text('El anfitrión abandonó la sala. La partida ha sido cancelada.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver al lobby
                },
                child: Text('Volver al Lobby'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 🚀 Manejar inicio de partida desde el anfitrión
  void _handleGameStart(Map<String, dynamic> message) {
    print('🚀🚀🚀 RECIBIDO MENSAJE START_GAME 🚀🚀🚀');
    print('📨 Mensaje completo: $message');
    print('🎯 Mi sala: ${widget.roomCode}');
    print('🏠 ¿Soy anfitrión?: ${widget.isHost}');
    
    // Verificar que el mensaje sea válido
    final messageRoom = message['roomCode'] ?? message['room_code'] ?? message['room'];
    print('🔍 Sala del mensaje: $messageRoom');
    
    if (messageRoom != null && messageRoom != widget.roomCode) {
      print('❌ MENSAJE START_GAME PARA SALA DIFERENTE: $messageRoom vs ${widget.roomCode}');
      return;
    }
    
    // Verificar si es mensaje de inicio de juego válido
    final isGameStart = message['type'] == 'start_game' || 
                       message['type'] == 'game_start' ||
                       message['action'] == 'game_starting' ||
                       message['gameStarted'] == true;
                       
    if (!isGameStart) {
      print('❌ No es un mensaje válido de inicio de juego');
      return;
    }
    
    // Solo procesar si NO soy el anfitrión (el anfitrión ya navega por su cuenta)
    if (!widget.isHost) {
      print('🎮 Iniciando partida automáticamente - Cliente');
      
      // Actualizar lista de jugadores con los datos del mensaje si es necesario
      final playersFromMessage = message['players'] as List<dynamic>?;
      if (playersFromMessage != null) {
        // Aquí podrías actualizar connectedPlayers si es necesario
        print('📋 Datos de jugadores en start_game: ${playersFromMessage.length} jugadores');
      }
      
      // Navegar automáticamente al juego
      if (mounted) {
        _navigateToOnlineGameAutomatically();
      }
    } else {
      print('🏠 Anfitrión - Ignorando mensaje start_game propio');
    }
  }

  /// 🎮 Navegar al juego automáticamente (para clientes, sin enviar mensaje)
  void _navigateToOnlineGameAutomatically() {
    print('🎮 Navegando automáticamente al juego online...');
    
    // 🎯 Preparar datos para modo online (mismo código que _navigateToOnlineGame pero sin enviar mensaje)
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
      if (playerColor == Colors.blue) {
        colorIndex = 1;
      } else if (playerColor == Colors.green) colorIndex = 2;
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
          onlinePlayerIndex: _getMyPlayerIndex(), // Calcular índice correcto del jugador actual
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _messageSubscription?.cancel(); // 🧹 Limpiar suscripción WebSocket
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
            SizedBox(
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
          SizedBox(
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

  /// 🔍 Obtener el índice del jugador actual en la lista de jugadores conectados
  int _getMyPlayerIndex() {
    final myClientId = _webSocketService.uniqueClientId;
    
    for (int i = 0; i < connectedPlayers.length; i++) {
      final playerId = connectedPlayers[i]['id'] ?? connectedPlayers[i]['clientId'];
      if (playerId == myClientId) {
        print('🎯 Mi índice de jugador: $i (ID: $myClientId)');
        return i;
      }
    }
    
    // Fallback: si no se encuentra, asumir que es el primer jugador (anfitrión)
    print('⚠️ No se encontró índice del jugador, usando 0 (anfitrión)');
    return 0;
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
    // 🌐 ENVIAR MENSAJE DE INICIO SOLO SI SOY ANFITRIÓN
    if (widget.isHost) {
      print('🚀🚀🚀 ANFITRIÓN ENVIANDO START_GAME 🚀🚀🚀');
      print('🎯 Sala: ${widget.roomCode}');
      print('👥 Jugadores conectados: ${connectedPlayers.length}');
      
      // 🚀 INTENTAR MÚLTIPLES TIPOS DE MENSAJES PARA ASEGURAR QUE LLEGUE
      final gameStartMessage1 = {
        'type': 'game_start',  // Variación 1
        'action': 'start_game',
        'roomCode': widget.roomCode,
        'players': connectedPlayers.map((player) => {
          'name': player['name'],
          'color': player['color'].toString(),
          'id': player['id'] ?? player['clientId'],
          'isHost': player['isHost'] ?? false,
        }).toList(),
        'startedBy': _webSocketService.uniqueClientId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final gameStartMessage2 = {
        'type': 'room_updated',  // Usar tipo que sabemos que funciona
        'action': 'game_starting',
        'roomCode': widget.roomCode,
        'gameStarted': true,
        'startedBy': _webSocketService.uniqueClientId,
        'players': connectedPlayers.length,
      };

      final gameStartMessage3 = {
        'type': 'start_game',  // Mensaje original
        'roomCode': widget.roomCode,
        'players': connectedPlayers.map((player) => {
          'name': player['name'],
          'color': player['color'].toString(),
          'id': player['id'] ?? player['clientId'],
          'isHost': player['isHost'] ?? false,
        }).toList(),
        'startedBy': _webSocketService.uniqueClientId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      print('📤 Enviando múltiples mensajes para asegurar llegada:');
      print('   📤1 game_start: $gameStartMessage1');
      print('   📤2 room_updated: $gameStartMessage2'); 
      print('   📤3 start_game: $gameStartMessage3');
      
      _webSocketService.sendMessage(gameStartMessage1);
      _webSocketService.sendMessage(gameStartMessage2);
      _webSocketService.sendMessage(gameStartMessage3);
      
      print('✅ Todos los mensajes start_game enviados');
    } else {
      print('👥 Cliente - No enviando mensaje start_game');
    }

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
      if (playerColor == Colors.blue) {
        colorIndex = 1;
      } else if (playerColor == Colors.green) colorIndex = 2;
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
          onlinePlayerIndex: _getMyPlayerIndex(), // Calcular índice correcto del jugador actual
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
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              
              if (widget.isHost) {
                // 🔒 Anfitrión cierra la sala
                print('🔒 Anfitrión cerrando sala: ${widget.roomCode}');
                
                // Intentar múltiples mensajes para asegurar que el servidor entienda
                _webSocketService.sendMessage({
                  'type': 'close_room',
                  'roomCode': widget.roomCode,
                  'clientId': _webSocketService.uniqueClientId,
                });
                
                _webSocketService.sendMessage({
                  'type': 'room_closed', 
                  'roomCode': widget.roomCode,
                  'closedBy': _webSocketService.uniqueClientId,
                });
                
                await _webSocketService.closeRoom();
                
                print('🔒 Enviados múltiples mensajes de cierre');
              } else {
                // 🚪 Jugador sale de la sala
                print('🚪 Jugador saliendo de sala: ${widget.roomCode}');
                _webSocketService.leaveRoom();
              }
              
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