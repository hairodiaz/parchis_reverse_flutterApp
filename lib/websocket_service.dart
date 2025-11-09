import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math'; // ✅ AGREGAR para generar IDs únicos
import 'models/online_game_models.dart'; // ✅ AGREGAR modelos online

/// 🚀 WEBSOCKET SERVICE - REEMPLAZO DE FIREBASE
/// 
/// Ventajas:
/// - ✅ Conexión instantánea
/// - ✅ Cleanup automático al desconectar
/// - ✅ Control total del estado
/// - ✅ Latencia mínima
/// - ✅ Sin problemas de Firebase

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal() {
    // 🎯 GENERAR ID ÚNICO POR EMULADOR/DISPOSITIVO
    _uniqueClientId = _generateUniqueClientId();
  }

  WebSocket? _socket;
  String? _currentRoomCode;
  String? _currentPlayerId;
  String? _uniqueClientId; // ✅ ID único para este cliente
  bool _isConnected = false;
  
  // 📡 Stream controllers para eventos
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _connectionController = 
      StreamController<String>.broadcast();
  
  // 🎮 Streams públicos
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  
  // 📊 Getters
  bool get isConnected => _isConnected;
  String? get currentRoomCode => _currentRoomCode;
  String? get currentPlayerId => _currentPlayerId;
  String? get uniqueClientId => _uniqueClientId; // ✅ Getter para ID único

  /// 🎯 Generar ID único para este cliente/emulador
  String _generateUniqueClientId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    final clientId = 'client_${timestamp}_$random';
    print('🆔 ID único generado: $clientId');
    return clientId;
  }

  /// 🔌 Conectar al servidor WebSocket
  Future<bool> connect({String? serverUrl}) async {
    try {
      // 🌐 CONFIGURACIÓN PARA RAILWAY (PRODUCCIÓN)
      // - Railway WebSocket: wss://tu-servidor.railway.app
      // - Para testing local: ws://10.0.2.2:8080 (emulador) o ws://localhost:8080
      final url = serverUrl ?? 'wss://parchisreverseflutterapp-production.up.railway.app'; // ✅ Servidor Railway
      
      print('🔌 Conectando a WebSocket: $url');
      
      _socket = await WebSocket.connect(url);
      _isConnected = true;
      
      print('✅ Conectado al servidor WebSocket');
      _connectionController.add('connected');
      
      // 📩 Escuchar mensajes del servidor
      _socket!.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            print('📨 Mensaje recibido: ${message['type']}');
            _messageController.add(message);
          } catch (e) {
            print('❌ Error decodificando mensaje: $e');
          }
        },
        onError: (error) {
          print('❌ Error en WebSocket: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('🔌 Conexión WebSocket cerrada');
          _handleDisconnection();
        },
      );
      
      return true;
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
      _isConnected = false;
      _connectionController.add('error');
      return false;
    }
  }

  /// 🚪 Crear nueva sala
  Future<String?> createRoom(String playerName, {String? playerColor}) async {
    if (!_isConnected || _socket == null) {
      print('❌ No conectado al servidor');
      return null;
    }
    
    try {
      final message = {
        'type': 'create_room',
        'playerName': playerName,
        'playerColor': playerColor ?? 'red',
        'clientId': _uniqueClientId, // ✅ ID único del cliente
      };
      
      print('🏠 Creando sala para $playerName (Cliente: $_uniqueClientId)');
      _socket!.add(jsonEncode(message));
      
      // Esperar respuesta del servidor
      final completer = Completer<String?>();
      late StreamSubscription subscription;
      
      subscription = messageStream.listen((data) {
        if (data['type'] == 'room_created') {
          _currentRoomCode = data['roomCode'];
          _currentPlayerId = data['playerId'];
          print('✅ Sala creada: $_currentRoomCode');
          subscription.cancel();
          completer.complete(_currentRoomCode);
        } else if (data['type'] == 'error') {
          print('❌ Error creando sala: ${data['message']}');
          subscription.cancel();
          completer.complete(null);
        }
      });
      
      // Timeout después de 5 segundos
      Timer(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.complete(null);
        }
      });
      
      return await completer.future;
    } catch (e) {
      print('❌ Error enviando mensaje crear sala: $e');
      return null;
    }
  }

  /// 🚪 Unirse a sala existente
  Future<bool> joinRoom(String roomCode, String playerName, {String? playerColor}) async {
    if (!_isConnected || _socket == null) {
      print('❌ No conectado al servidor');
      return false;
    }
    
    try {
      final message = {
        'type': 'join_room',
        'roomCode': roomCode,
        'playerName': playerName,
        'playerColor': playerColor ?? 'blue',
        'clientId': _uniqueClientId, // ✅ ID único del cliente
      };
      
      print('🚪 Uniéndose a sala $roomCode como $playerName (Cliente: $_uniqueClientId)');
      _socket!.add(jsonEncode(message));
      
      // Esperar respuesta del servidor
      final completer = Completer<bool>();
      late StreamSubscription subscription;
      
      subscription = messageStream.listen((data) {
        if (data['type'] == 'room_joined') {
          _currentRoomCode = data['roomCode'];
          _currentPlayerId = data['playerId'];
          print('✅ Unido a sala: $_currentRoomCode');
          subscription.cancel();
          completer.complete(true);
        } else if (data['type'] == 'error') {
          print('❌ Error uniéndose a sala: ${data['message']}');
          subscription.cancel();
          completer.complete(false);
        }
      });
      
      // Timeout después de 5 segundos
      Timer(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.complete(false);
        }
      });
      
      return await completer.future;
    } catch (e) {
      print('❌ Error enviando mensaje unirse a sala: $e');
      return false;
    }
  }

  /// 🚪 Salir de la sala actual
  void leaveRoom() {
    if (!_isConnected || _socket == null || _currentRoomCode == null) {
      return;
    }
    
    try {
      final message = {'type': 'leave_room'};
      
      print('🚪 Saliendo de sala $_currentRoomCode');
      _socket!.add(jsonEncode(message));
      
      _currentRoomCode = null;
      _currentPlayerId = null;
    } catch (e) {
      print('❌ Error enviando mensaje salir de sala: $e');
    }
  }

  /// 🎲 Enviar resultado de dado
  void sendDiceRoll(int diceValue, int currentPlayer) {
    if (!_isConnected || _socket == null || _currentRoomCode == null) {
      return;
    }
    
    try {
      final message = {
        'type': 'dice_roll',
        'diceValue': diceValue,
        'currentPlayer': currentPlayer,
      };
      
      print('🎲 Enviando dado: $diceValue');
      _socket!.add(jsonEncode(message));
    } catch (e) {
      print('❌ Error enviando dado: $e');
    }
  }

  /// 🎮 Enviar movimiento de pieza
  void sendGameMove(List<Map<String, dynamic>> pieces, int currentPlayer) {
    if (!_isConnected || _socket == null || _currentRoomCode == null) {
      return;
    }
    
    try {
      final message = {
        'type': 'game_move',
        'pieces': pieces,
        'currentPlayer': currentPlayer,
      };
      
      print('🎮 Enviando movimiento');
      _socket!.add(jsonEncode(message));
    } catch (e) {
      print('❌ Error enviando movimiento: $e');
    }
  }

  /// 🔌 Manejar desconexión
  void _handleDisconnection() {
    _isConnected = false;
    _currentRoomCode = null;
    _currentPlayerId = null;
    _connectionController.add('disconnected');
  }

  /// 🔌 Desconectar manualmente
  void disconnect() {
    print('🔌 Desconectando WebSocket');
    
    // Salir de sala si estamos en una
    if (_currentRoomCode != null) {
      leaveRoom();
    }
    
    _socket?.close();
    _handleDisconnection();
  }

  /// 🧹 Limpiar recursos
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }

  // 🔄 MÉTODOS DE COMPATIBILIDAD CON FIREBASE (temporales para migración)
  
  /// Obtener salas públicas desde el servidor WebSocket
  Future<List<OnlineGameRoom>> getPublicRooms() async {
    // 🔌 Auto-conectar si no estamos conectados
    if (!_isConnected) {
      print('🔌 Auto-conectando a WebSocket...');
      final connected = await connect();
      if (!connected) {
        print('❌ No se pudo conectar al servidor WebSocket');
        // 🧪 DATOS DE PRUEBA mientras solucionamos el servidor
        return _generateTestRooms();
      }
    }
    
    try {
      print('📋 Solicitando salas públicas al servidor...');
      
      // Enviar solicitud al servidor
      _socket!.add(jsonEncode({
        'type': 'get_public_rooms'
      }));
      
      // Esperar respuesta del servidor
      final completer = Completer<List<OnlineGameRoom>>();
      late StreamSubscription subscription;
      
      subscription = messageStream.listen((data) {
        if (data['type'] == 'public_rooms') {
          print('✅ Salas públicas recibidas: ${data['rooms']?.length ?? 0}');
          
          // Convertir datos del servidor a OnlineGameRoom
          final roomsData = data['rooms'] as List? ?? [];
          final rooms = roomsData.map((roomData) {
            // Convertir formato WebSocket a formato Firebase (compatibilidad)
            return OnlineGameRoom(
              roomCode: roomData['roomCode'] ?? '',
              players: [], // Lista vacía por ahora, se llenará cuando se necesite
              gameState: OnlineGameState(
                currentPlayer: 0,
                diceValue: 1,
                pieces: [], // Lista vacía de piezas
              ),
              status: roomData['status'] ?? 'waiting',
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                roomData['createdAt'] ?? DateTime.now().millisecondsSinceEpoch
              ),
            );
          }).toList();
          
          subscription.cancel();
          completer.complete(rooms);
        } else if (data['type'] == 'error') {
          print('❌ Error obteniendo salas: ${data['message']}');
          subscription.cancel();
          completer.complete(<OnlineGameRoom>[]);
        }
      });
      
      // Timeout después de 5 segundos
      Timer(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('⏰ Timeout obteniendo salas públicas - usando datos de prueba');
          subscription.cancel();
          completer.complete(_generateTestRooms());
        }
      });
      
      return await completer.future;
    } catch (e) {
      print('❌ Error solicitando salas públicas: $e');
      return _generateTestRooms();
    }
  }

  /// 🧪 Generar salas de prueba mientras solucionamos el servidor
  List<OnlineGameRoom> _generateTestRooms() {
    print('🧪 Generando salas de prueba...');
    return [
      OnlineGameRoom(
        roomCode: 'DEMO1',
        players: [
          OnlinePlayer(
            id: 'p1',
            name: 'JugadorHost1',
            color: 'red',
            isHost: true,
            joinedAt: DateTime.now().subtract(Duration(minutes: 5)),
          ),
        ],
        gameState: OnlineGameState(
          currentPlayer: 0,
          diceValue: 1,
          pieces: [],
        ),
        status: 'waiting',
        createdAt: DateTime.now().subtract(Duration(minutes: 5)),
      ),
      OnlineGameRoom(
        roomCode: 'DEMO2',
        players: [
          OnlinePlayer(
            id: 'p2',
            name: 'JugadorHost2',
            color: 'blue',
            isHost: true,
            joinedAt: DateTime.now().subtract(Duration(minutes: 2)),
          ),
        ],
        gameState: OnlineGameState(
          currentPlayer: 0,
          diceValue: 1,
          pieces: [],
        ),
        status: 'waiting',
        createdAt: DateTime.now().subtract(Duration(minutes: 2)),
      ),
      OnlineGameRoom(
        roomCode: 'DEMO3',
        players: [
          OnlinePlayer(
            id: 'p3',
            name: 'JugadorHost3',
            color: 'green',
            isHost: true,
            joinedAt: DateTime.now().subtract(Duration(minutes: 1)),
          ),
          OnlinePlayer(
            id: 'p4',
            name: 'Invitado1',
            color: 'yellow',
            isHost: false,
            joinedAt: DateTime.now().subtract(Duration(seconds: 30)),
          ),
        ],
        gameState: OnlineGameState(
          currentPlayer: 0,
          diceValue: 1,
          pieces: [],
        ),
        status: 'waiting',
        createdAt: DateTime.now().subtract(Duration(minutes: 1)),
      ),
    ];
  }

  /// Unirse a sala (compatibilidad con API de Firebase)
  Future<String?> joinGameRoom(String roomCode, OnlinePlayer player) async {
    final success = await joinRoom(roomCode, player.name, playerColor: player.color);
    return success ? roomCode : null;
  }

  /// Obtener información de sala (temporal con datos de prueba)
  Future<OnlineGameRoom?> getRoomInfo(String roomCode) async {
    print('🔍 Obteniendo info de sala: $roomCode (Cliente: $_uniqueClientId)');
    
    // 🧪 DATOS DE PRUEBA para que la pantalla funcione
    if (roomCode.isNotEmpty) {
      return OnlineGameRoom(
        roomCode: roomCode,
        players: [
          OnlinePlayer(
            id: 'host_$roomCode',
            name: 'Host-$roomCode',
            color: 'red',
            isHost: true,
            joinedAt: DateTime.now().subtract(Duration(minutes: 5)),
          ),
          // Simular que el cliente actual es el segundo jugador
          OnlinePlayer(
            id: _uniqueClientId ?? 'guest_default',
            name: 'Cliente-${_uniqueClientId?.substring(7, 12) ?? 'Guest'}',
            color: 'blue',
            isHost: false,
            joinedAt: DateTime.now(),
          ),
        ],
        gameState: OnlineGameState(
          currentPlayer: 0,
          diceValue: 1,
          pieces: [],
        ),
        status: 'waiting', // Estado esperando por defecto
        createdAt: DateTime.now().subtract(Duration(minutes: 5)),
      );
    }
    
    return null;
  }

  /// Observar estado del juego (temporal)
  Stream<OnlineGameState?> watchGameState(String roomCode) {
    // TODO: Implementar stream de estado de juego
    return Stream.value(null);
  }

  /// Actualizar estado del juego (temporal)
  Future<void> updateGameState(String roomCode, Map<String, dynamic> gameState) async {
    // TODO: Implementar actualización de estado
    print('⚠️ updateGameState() - Método temporal');
  }

  /// Lanzar dado (temporal)
  Future<void> rollDice(String roomCode, int diceValue) async {
    sendDiceRoll(diceValue, 0); // currentPlayer será manejado por el servidor
  }

  /// Siguiente turno (temporal)
  Future<void> nextTurn(String roomCode, int currentPlayerIndex) async {
    // TODO: Implementar cambio de turno
    print('⚠️ nextTurn() - Método temporal');
  }

  /// Mover o capturar pieza (temporal)
  Future<void> moveOrCapturePiece(String roomCode, dynamic piece) async {
    // TODO: Implementar movimiento de pieza
    print('⚠️ moveOrCapturePiece() - Método temporal');
  }

  /// Salir de sala antes del juego (compatibilidad)
  Future<void> leaveRoomPreGame() async {
    leaveRoom();
  }
}

/// 📋 MODELOS DE DATOS PARA WEBSOCKET

class WebSocketPlayer {
  final String id;
  final String name;
  final String color;
  final bool isHost;
  final DateTime joinedAt;

  WebSocketPlayer({
    required this.id,
    required this.name,
    required this.color,
    required this.isHost,
    required this.joinedAt,
  });

  factory WebSocketPlayer.fromMap(Map<String, dynamic> map) {
    return WebSocketPlayer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? 'red',
      isHost: map['isHost'] ?? false,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'isHost': isHost,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
    };
  }
}

class WebSocketRoom {
  final String roomCode;
  final List<WebSocketPlayer> players;
  final Map<String, dynamic> gameState;
  final String status;
  final DateTime createdAt;

  WebSocketRoom({
    required this.roomCode,
    required this.players,
    required this.gameState,
    required this.status,
    required this.createdAt,
  });

  factory WebSocketRoom.fromMap(Map<String, dynamic> map) {
    final playersData = map['players'] as List? ?? [];
    final players = playersData
        .map((p) => WebSocketPlayer.fromMap(p as Map<String, dynamic>))
        .toList();

    return WebSocketRoom(
      roomCode: map['roomCode'] ?? '',
      players: players,
      gameState: Map<String, dynamic>.from(map['gameState'] ?? {}),
      status: map['status'] ?? 'waiting',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomCode': roomCode,
      'players': players.map((p) => p.toMap()).toList(),
      'gameState': gameState,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}