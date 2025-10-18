import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';
import 'dart:async';

// Modelo de estado del juego online
class OnlineGameState {
  final int currentPlayerIndex;
  final int diceValue;
  final List<OnlineGamePiece> pieces;
  final String? lastMessage;
  final bool isMoving;
  final DateTime lastUpdate;
  final bool gameEnded;
  final String? winner;
  final String? winReason;

  OnlineGameState({
    required this.currentPlayerIndex,
    required this.diceValue,
    required this.pieces,
    this.lastMessage,
    this.isMoving = false,
    required this.lastUpdate,
    this.gameEnded = false,
    this.winner,
    this.winReason,
  });

  factory OnlineGameState.fromMap(Map<String, dynamic> map) {
    try {
      final piecesRaw = map['pieces'] as List<dynamic>? ?? [];
      final pieces = piecesRaw
          .map((p) {
            if (p is Map) {
              return OnlineGamePiece.fromMap(Map<String, dynamic>.from(p));
            }
            throw Exception('Invalid piece data: $p');
          })
          .toList();

      return OnlineGameState(
        currentPlayerIndex: map['currentPlayerIndex'] ?? 0,
        diceValue: map['diceValue'] ?? 1,
        pieces: pieces,
        lastMessage: map['lastMessage'],
        isMoving: map['isMoving'] ?? false,
        lastUpdate: DateTime.fromMillisecondsSinceEpoch(map['lastUpdate'] ?? 0),
        gameEnded: map['gameEnded'] ?? false,
        winner: map['winner'],
        winReason: map['winReason'],
      );
    } catch (e) {
      print('❌ Error en OnlineGameState.fromMap: $e');
      rethrow;
    }
  }

  static OnlineGameState createDefaultGameState(int numPlayers) {
    // Crear fichas iniciales en posición de salida (9,0)
    final pieces = <OnlineGamePiece>[];
    final colors = ['red', 'blue', 'green', 'yellow'];
    
    for (int i = 0; i < numPlayers; i++) {
      pieces.add(OnlineGamePiece(
        id: '${i + 1}',
        playerIndex: i,
        color: colors[i],
        row: 9,
        col: 0,
      ));
    }

    return OnlineGameState(
      currentPlayerIndex: 0,
      diceValue: 1,
      pieces: pieces,
      lastUpdate: DateTime.now(),
      gameEnded: false,
      winner: null,
      winReason: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentPlayerIndex': currentPlayerIndex,
      'diceValue': diceValue,
      'pieces': pieces.map((p) => p.toMap()).toList(),
      'lastMessage': lastMessage,
      'isMoving': isMoving,
      'lastUpdate': lastUpdate.millisecondsSinceEpoch,
      'gameEnded': gameEnded,
      'winner': winner,
      'winReason': winReason,
    };
  }

  OnlineGameState copyWith({
    int? currentPlayerIndex,
    int? diceValue,
    List<OnlineGamePiece>? pieces,
    String? lastMessage,
    bool? isMoving,
    DateTime? lastUpdate,
    bool? gameEnded,
    String? winner,
    String? winReason,
  }) {
    return OnlineGameState(
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      diceValue: diceValue ?? this.diceValue,
      pieces: pieces ?? this.pieces,
      lastMessage: lastMessage ?? this.lastMessage,
      isMoving: isMoving ?? this.isMoving,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      gameEnded: gameEnded ?? this.gameEnded,
      winner: winner ?? this.winner,
      winReason: winReason ?? this.winReason,
    );
  }
}

// Modelo de ficha online
class OnlineGamePiece {
  final String id;
  final int playerIndex;
  final String color;
  final int row;
  final int col;

  OnlineGamePiece({
    required this.id,
    required this.playerIndex,
    required this.color,
    required this.row,
    required this.col,
  });

  factory OnlineGamePiece.fromMap(Map<String, dynamic> map) {
    return OnlineGamePiece(
      id: map['id'] ?? '',
      playerIndex: map['playerIndex'] ?? 0,
      color: map['color'] ?? 'red',
      row: map['row'] ?? 0,
      col: map['col'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerIndex': playerIndex,
      'color': color,
      'row': row,
      'col': col,
    };
  }
}

// Modelo de datos para sala de juego online
class OnlineGameRoom {
  final String roomId;
  final String hostPlayer;
  final List<OnlinePlayer> players;
  final OnlineGameState gameState;
  final String status; // 'waiting', 'playing', 'finished'
  final bool isPublic; // true = pública (aparece en lista), false = privada (solo con código)
  final DateTime createdAt;

  OnlineGameRoom({
    required this.roomId,
    required this.hostPlayer,
    required this.players,
    required this.gameState,
    required this.status,
    required this.isPublic,
    required this.createdAt,
  });

  factory OnlineGameRoom.fromMap(Map<String, dynamic> map, String roomId) {
    try {
      // Convierte el mapa de jugadores a Map<String, Map> de forma robusta
      final playersRaw = map['players'];
      final playersMap = (playersRaw is Map)
          ? playersRaw.map((key, value) => MapEntry(key.toString(), value as Map))
          : <String, Map>{};

      print('✅ Parseando sala $roomId con ${playersMap.length} jugadores');

      final players = playersMap.entries
          .map((e) => OnlinePlayer.fromMap(Map<String, dynamic>.from(e.value), e.key))
          .toList();

      // Parsear gameState de forma robusta
      final gameStateRaw = map['gameState'];
      late OnlineGameState gameState;
      
      if (gameStateRaw != null && gameStateRaw is Map) {
        final gameStateMap = Map<String, dynamic>.from(gameStateRaw);
        gameState = OnlineGameState.fromMap(gameStateMap);
      } else {
        gameState = OnlineGameState.createDefaultGameState(players.length);
      }

      return OnlineGameRoom(
        roomId: roomId,
        hostPlayer: map['hostPlayer'] ?? '',
        players: players,
        gameState: gameState,
        status: map['status'] ?? 'waiting',
        isPublic: map['isPublic'] ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      );
    } catch (e) {
      print('❌ Error en OnlineGameRoom.fromMap: $e');
      print('❌ Datos recibidos: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'hostPlayer': hostPlayer,
      'players': {
        for (var player in players) player.playerId: player.toMap()
      },
      'gameState': gameState.toMap(),
      'status': status,
      'isPublic': isPublic,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

// Modelo de jugador online
class OnlinePlayer {
  final String playerId;
  final String name;
  final String avatarColor;
  final String level;
  final bool isHost;
  final bool isConnected;

  OnlinePlayer({
    required this.playerId,
    required this.name,
    required this.avatarColor,
    required this.level,
    this.isHost = false,
    this.isConnected = true,
  });

  factory OnlinePlayer.fromMap(Map<String, dynamic> map, String playerId) {
    return OnlinePlayer(
      playerId: playerId,
      name: map['name'] ?? '',
      avatarColor: map['avatarColor'] ?? 'blue',
      level: map['level'] ?? 'Principiante',
      isHost: map['isHost'] ?? false,
      isConnected: map['isConnected'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatarColor': avatarColor,
      'level': level,
      'isHost': isHost,
      'isConnected': isConnected,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

// Servicio principal de Firebase
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseDatabase? _database;
  String? _currentRoomId;
  String? _currentPlayerId;
  Timer? _heartbeatTimer;
  Timer? _abandonmentCheckTimer;
  Timer? _cleanupTimer;

  // Inicializar Firebase
  static Future<void> initialize() async {
    try {
      // Firebase ya fue inicializado en main.dart
      print('✅ FirebaseService configurado correctamente');
    } catch (e) {
      print('❌ Error en FirebaseService: $e');
      // Continuar sin Firebase para modo offline
    }
  }

  // Verificar si Firebase está disponible
  bool get isAvailable {
    try {
      // Verificar si Firebase está inicializado
      if (Firebase.apps.isEmpty) return false;
      
      _database ??= FirebaseDatabase.instance;
      
      // Verificar si las credenciales están configuradas correctamente
      final app = Firebase.app();
      if (app.options.projectId != 'parchis-reverse-app' || 
          app.options.apiKey.contains('TU_') || 
          app.options.apiKey.isEmpty) {
        return false; // Credenciales no configuradas
      }
      
      return _database != null;
    } catch (e) {
      print('Firebase no disponible: $e');
      return false;
    }
  }

  // Generar código de sala único
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  // Crear nueva sala de juego
  Future<String?> createGameRoom(OnlinePlayer hostPlayer, {bool isPublic = false}) async {
    if (!isAvailable) return null;

    try {
      final roomCode = _generateRoomCode();
      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      
      // Crear estado inicial del juego
      final initialGameState = OnlineGameState.createDefaultGameState(1);
      
      final room = OnlineGameRoom(
        roomId: roomCode,
        hostPlayer: playerId,
        players: [hostPlayer.copyWith(playerId: playerId, isHost: true)],
        gameState: initialGameState,
        status: 'waiting',
        isPublic: isPublic,
        createdAt: DateTime.now(),
      );

      await _database!.ref('gameRooms/$roomCode').set(room.toMap());
      
      // Si es sala pública, añadirla también a la lista de salas públicas para consulta rápida
      if (isPublic) {
        await _database!.ref('publicRooms/$roomCode').set({
          'roomId': roomCode,
          'hostName': hostPlayer.name,
          'playerCount': 1,
          'maxPlayers': 4,
          'status': 'waiting',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      _currentRoomId = roomCode;
      _currentPlayerId = playerId;
      
      // Iniciar heartbeat para detección de abandono
      _startHeartbeat();
      
      print('✅ Sala creada: $roomCode');
      return roomCode;
    } catch (e) {
      print('❌ Error creando sala: $e');
      return null;
    }
  }

  // Unirse a sala existente
  Future<bool> joinGameRoom(String roomCode, OnlinePlayer player) async {
    if (!isAvailable) return false;

    try {
      // Normaliza el código de sala (mayúsculas y sin espacios)
      final normalizedCode = roomCode.trim().toUpperCase();
      final roomRef = _database!.ref('gameRooms/$normalizedCode');
      final snapshot = await roomRef.get();

      if (!snapshot.exists) {
        print('❌ Sala no encontrada: $normalizedCode');
        return false;
      }

    // Convierte el snapshot a Map<String, dynamic> de forma robusta
    final rawData = snapshot.value;
    final roomData = (rawData is Map)
      ? rawData.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};
    final room = OnlineGameRoom.fromMap(roomData, normalizedCode);

      if (room.players.length >= 4) {
        print('❌ Sala llena: $normalizedCode');
        return false;
      }

      if (room.status != 'waiting') {
        print('❌ Partida ya iniciada: $normalizedCode');
        return false;
      }

      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      await roomRef.child('players/$playerId').set(
        player.copyWith(playerId: playerId).toMap()
      );

      // Actualizar contador en sala pública si es pública
      if (room.isPublic) {
        await _database!.ref('publicRooms/$normalizedCode').update({
          'playerCount': room.players.length + 1,
        });
      }

      _currentRoomId = normalizedCode;
      _currentPlayerId = playerId;

      // Iniciar heartbeat para detección de abandono
      _startHeartbeat();

      print('✅ Unido a sala: $normalizedCode');
      return true;
    } catch (e) {
      print('❌ Error uniéndose a sala: $e');
      return false;
    }
  }

  // Escuchar cambios en la sala
  Stream<OnlineGameRoom?> watchGameRoom(String roomCode) {
    if (!isAvailable) return Stream.value(null);

    return _database!.ref('gameRooms/$roomCode').onValue.map((event) {
      if (!event.snapshot.exists) {
        print('❌ Sala no encontrada en watchGameRoom: $roomCode');
        return null;
      }
      
      try {
        // Convierte el snapshot a Map<String, dynamic> de forma robusta
        final rawData = event.snapshot.value;
        final roomData = (rawData is Map)
          ? rawData.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{};
        
        print('✅ Datos de sala recibidos: ${roomData.keys}');
        return OnlineGameRoom.fromMap(roomData, roomCode);
      } catch (e) {
        print('❌ Error parseando datos de sala: $e');
        return null;
      }
    });
  }

  // Actualizar estado del juego (método mejorado)
  Future<void> updateGameState(String roomCode, Map<String, dynamic> gameState) async {
    if (!isAvailable) return;

    try {
      // Si recibe un mapa simple, actualizamos con timestamp
      final updateData = Map<String, dynamic>.from(gameState);
      updateData['lastUpdate'] = DateTime.now().millisecondsSinceEpoch;
      
      await _database!.ref('gameRooms/$roomCode/gameState').update(updateData);
      print('✅ Estado del juego actualizado: $roomCode');
    } catch (e) {
      print('❌ Error actualizando estado: $e');
    }
  }

  // Actualizar estado de la sala (waiting, playing, finished)
  Future<void> updateRoomStatus(String roomCode, String status) async {
    if (!isAvailable) return;

    try {
      await _database!.ref('gameRooms/$roomCode/status').set(status);
      print('✅ Estado de sala actualizado: $status');
    } catch (e) {
      print('❌ Error actualizando estado de sala: $e');
    }
  }

  // Salir de la sala antes de que inicie la partida
  Future<void> leaveRoomPreGame() async {
    if (!isAvailable || _currentRoomId == null || _currentPlayerId == null) return;

    try {
      final roomRef = _database!.ref('gameRooms/$_currentRoomId');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) return;
      
      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) return;
      
      final data = Map<String, dynamic>.from(rawData);
      final playersData = data['players'];
      
      // Verificar si playersData es un Map válido
      Map<String, dynamic>? playersMap;
      if (playersData is Map) {
        playersMap = Map<String, dynamic>.from(playersData);
      }
      
      final isHost = playersMap?[_currentPlayerId]?['isHost'] as bool? ?? false;
      
      if (isHost) {
        // Si es el host, notificar eliminación y luego eliminar sala
        await roomRef.child('status').set('deleted');
        await roomRef.child('deleteReason').set('Host left room');
        
        // Eliminar de salas públicas si es pública
        final isPublic = data['isPublic'] as bool? ?? false;
        if (isPublic) {
          await _database!.ref('publicRooms/$_currentRoomId').remove();
        }
        
        // Eliminar sala después de un pequeño delay para que otros puedan leer la notificación
        await Future.delayed(Duration(seconds: 2));
        await roomRef.remove();
        
        print('🏠 Host eliminó la sala');
      } else {
        // Si es un jugador regular, solo removerlo
        await roomRef.child('players/$_currentPlayerId').remove();
        
        // Actualizar contador en sala pública si es pública
        final isPublic = data['isPublic'] as bool? ?? false;
        if (isPublic) {
          final playersCount = (playersMap?.length ?? 0) - 1;
          await _database!.ref('publicRooms/$_currentRoomId').update({
            'playerCount': playersCount.clamp(0, 4),
          });
        }
        
        // Notificar que un jugador se fue
        await roomRef.child('lastPlayerLeft').set({
          'playerId': _currentPlayerId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('👤 Jugador abandonó la sala');
      }
      
      // Verificar si la sala quedó vacía
      await _checkEmptyRoom(_currentRoomId!);
      
      // Detener heartbeat y limpiar referencias
      _stopHeartbeat();
      _currentRoomId = null;
      _currentPlayerId = null;
      
    } catch (e) {
      print('❌ Error saliendo de sala pre-partida: $e');
    }
  }

  // Salir de la sala durante la partida (con detección de abandono)
  Future<void> leaveRoom() async {
    if (!isAvailable || _currentRoomId == null || _currentPlayerId == null) return;

    try {
      // Marcar como desconectado en lugar de eliminar
      await _database!.ref('gameRooms/$_currentRoomId/players/$_currentPlayerId').update({
        'isConnected': false,
      });
      
      // Verificar auto-victoria
      await _checkAutoVictory();
      
      // Detener heartbeat
      _stopHeartbeat();
      
      // Limpiar referencias
      _currentRoomId = null;
      _currentPlayerId = null;
      
      print('✅ Sala abandonada correctamente');
    } catch (e) {
      print('❌ Error abandonando sala: $e');
    }
  }

  // Escuchar cambios en el estado del juego en tiempo real
  Stream<OnlineGameState?> watchGameState(String roomCode) {
    if (!isAvailable || roomCode.isEmpty) {
      return Stream.value(null);
    }

    return _database!.ref('gameRooms/$roomCode/gameState')
        .onValue
        .map((event) {
      try {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final rawData = event.snapshot.value;
          if (rawData is Map) {
            final data = Map<String, dynamic>.from(rawData);
            return OnlineGameState.fromMap(data);
          }
        }
        return null;
      } catch (e) {
        print('❌ Error en stream de estado del juego: $e');
        return null;
      }
    });
  }

  // Escuchar cambios en la sala (jugadores, estado, etc.)
  Stream<Map<String, dynamic>?> watchRoomChanges(String roomCode) {
    if (!isAvailable || roomCode.isEmpty) {
      return Stream.value(null);
    }

    return _database!.ref('gameRooms/$roomCode')
        .onValue
        .map((event) {
      try {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final rawData = event.snapshot.value;
          if (rawData is Map) {
            return Map<String, dynamic>.from(rawData);
          }
        }
        return null;
      } catch (e) {
        print('❌ Error en stream de cambios de sala: $e');
        return null;
      }
    });
  }

  // Métodos específicos para acciones del juego
  Future<bool> rollDice(String roomCode, int diceValue) async {
    if (!isAvailable || roomCode.isEmpty) return false;

    try {
      await _database!.ref('gameRooms/$roomCode/gameState').update({
        'diceValue': diceValue,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        'lastMessage': 'Dado lanzado: $diceValue',
      });
      print('✅ Dado lanzado: $diceValue en sala $roomCode');
      return true;
    } catch (e) {
      print('❌ Error lanzando dado: $e');
      return false;
    }
  }

  Future<bool> movePiece(String roomCode, OnlineGamePiece piece) async {
    if (!isAvailable || roomCode.isEmpty) return false;

    try {
      print('🔄 Moviendo ficha ${piece.id} del jugador ${piece.playerIndex} a (${piece.row},${piece.col})');
      
      // Obtener estado actual
      final snapshot = await _database!.ref('gameRooms/$roomCode/gameState').get();
      if (!snapshot.exists || snapshot.value == null) {
        print('❌ No existe estado de juego en Firebase');
        return false;
      }

      final rawData = snapshot.value;
      if (!(rawData is Map)) return false;
      
      final currentState = OnlineGameState.fromMap(
        Map<String, dynamic>.from(rawData)
      );

      print('📊 Estado actual: ${currentState.pieces.length} fichas');

      // Actualizar la pieza en el array
      final updatedPieces = currentState.pieces.map((p) {
        if (p.id == piece.id && p.playerIndex == piece.playerIndex) {
          print('🎯 Actualizando ficha ${p.id}: (${p.row},${p.col}) → (${piece.row},${piece.col})');
          return piece;
        }
        return p;
      }).toList();

      await _database!.ref('gameRooms/$roomCode/gameState').update({
        'pieces': updatedPieces.map((p) => p.toMap()).toList(),
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        'lastMessage': null, // No mostrar mensaje de movimiento
        'isMoving': false,
      });

      print('✅ Ficha ${piece.id} movida exitosamente en sala $roomCode');
      return true;
    } catch (e) {
      print('❌ Error moviendo pieza: $e');
      return false;
    }
  }

  Future<bool> nextTurn(String roomCode, int nextPlayerIndex) async {
    if (!isAvailable || roomCode.isEmpty) return false;

    try {
      await _database!.ref('gameRooms/$roomCode/gameState').update({
        'currentPlayerIndex': nextPlayerIndex,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        'lastMessage': 'Turno del jugador ${nextPlayerIndex + 1}',
        'isMoving': false,
      });
      print('✅ Turno cambiado al jugador $nextPlayerIndex en sala $roomCode');
      return true;
    } catch (e) {
      print('❌ Error cambiando turno: $e');
      return false;
    }
  }

  Future<bool> setMovingState(String roomCode, bool isMoving) async {
    if (!isAvailable || roomCode.isEmpty) return false;

    try {
      await _database!.ref('gameRooms/$roomCode/gameState').update({
        'isMoving': isMoving,
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error actualizando estado de movimiento: $e');
      return false;
    }
  }

  // Obtener información de la sala
  Future<OnlineGameRoom?> getRoomInfo(String roomCode) async {
    if (!isAvailable || roomCode.isEmpty) return null;

    try {
      final snapshot = await _database!.ref('gameRooms/$roomCode').get();
      if (snapshot.exists && snapshot.value != null) {
        final rawData = snapshot.value;
        if (rawData is Map) {
          final data = Map<String, dynamic>.from(rawData);
          return OnlineGameRoom.fromMap(data, roomCode);
        }
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo información de la sala: $e');
      return null;
    }
  }

  // Obtener lista de salas públicas disponibles
  Future<List<OnlineGameRoom>> getPublicRooms() async {
    if (!isAvailable) return [];

    try {
      // Obtener todas las salas y filtrar localmente
      final snapshot = await _database!.ref('gameRooms').get();
          
      if (!snapshot.exists) return [];

      final rooms = <OnlineGameRoom>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      
      for (final entry in data.entries) {
        try {
          final roomData = Map<String, dynamic>.from(entry.value as Map);
          final room = OnlineGameRoom.fromMap(roomData, entry.key.toString());
          
          // Filtrar: solo salas públicas, en estado 'waiting' con espacio disponible
          if (room.isPublic && room.status == 'waiting' && room.players.length < 4) {
            rooms.add(room);
          }
        } catch (e) {
          print('❌ Error parseando sala pública: $e');
        }
      }
      
      // Ordenar por fecha de creación (más recientes primero)
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return rooms;
    } catch (e) {
      print('❌ Error obteniendo salas públicas: $e');
      return [];
    }
  }

  // Sistema de detección de abandono
  void _startHeartbeat() {
    if (_currentRoomId == null || _currentPlayerId == null) return;
    
    _heartbeatTimer?.cancel();
    _abandonmentCheckTimer?.cancel();
    
    // Heartbeat cada 10 segundos
    _heartbeatTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        await _database!.ref('gameRooms/$_currentRoomId/players/$_currentPlayerId').update({
          'lastHeartbeat': DateTime.now().millisecondsSinceEpoch,
          'isConnected': true,
        });
      } catch (e) {
        print('❌ Error en heartbeat: $e');
      }
    });
    
    // Verificar abandono cada 15 segundos
    _abandonmentCheckTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      await checkPlayerAbandonment();
    });
    
    // Limpieza de salas cada 2 minutos (solo una instancia)
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(Duration(minutes: 2), (timer) async {
      await cleanupAbandonedRooms();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _abandonmentCheckTimer?.cancel();
    _cleanupTimer?.cancel();
    _heartbeatTimer = null;
    _abandonmentCheckTimer = null;
    _cleanupTimer = null;
  }

  // Verificar abandono de jugadores
  Future<void> checkPlayerAbandonment() async {
    if (_currentRoomId == null) return;
    
    try {
      final roomRef = _database!.ref('gameRooms/$_currentRoomId');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) return;
      
      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) return;
      
      final data = Map<String, dynamic>.from(rawData);
      final playersDataRaw = data['players'];
      
      // Verificar si playersData es un Map válido
      Map<String, dynamic>? playersData;
      if (playersDataRaw is Map) {
        playersData = Map<String, dynamic>.from(playersDataRaw);
      }
      
      if (playersData == null) return;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeoutMs = 30000; // 30 segundos timeout
      
      for (final entry in playersData.entries) {
        if (entry.value is! Map) continue;
        
        final playerData = Map<String, dynamic>.from(entry.value as Map);
        final lastHeartbeat = playerData['lastHeartbeat'] as int? ?? 0;
        final isConnected = playerData['isConnected'] as bool? ?? true;
        
        // Si el jugador no ha enviado heartbeat en 30 segundos, marcarlo como desconectado
        if (isConnected && (now - lastHeartbeat) > timeoutMs) {
          await roomRef.child('players/${entry.key}').update({
            'isConnected': false,
          });
          
          print('⚠️ Jugador ${entry.key} marcado como desconectado por inactividad');
          
          // Si solo queda un jugador conectado, declarar victoria automática
          await _checkAutoVictory();
        }
      }
    } catch (e) {
      print('❌ Error verificando abandono: $e');
    }
  }

  Future<void> _checkAutoVictory() async {
    if (_currentRoomId == null) return;
    
    try {
      final roomRef = _database!.ref('gameRooms/$_currentRoomId');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) return;
      
      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) return;
      
      final data = Map<String, dynamic>.from(rawData);
      final playersDataRaw = data['players'];
      
      // Verificar si playersData es un Map válido
      Map<String, dynamic>? playersData;
      if (playersDataRaw is Map) {
        playersData = Map<String, dynamic>.from(playersDataRaw);
      }
      
      if (playersData == null) return;
      
      // Contar jugadores conectados
      int connectedPlayers = 0;
      String? lastConnectedPlayerId;
      
      for (final entry in playersData.entries) {
        if (entry.value is! Map) continue;
        
        final playerData = Map<String, dynamic>.from(entry.value as Map);
        final isConnected = playerData['isConnected'] as bool? ?? true;
        
        if (isConnected) {
          connectedPlayers++;
          lastConnectedPlayerId = entry.key;
        }
      }
      
      // Si solo queda un jugador conectado, declarar victoria automática
      if (connectedPlayers == 1 && lastConnectedPlayerId != null) {
        await roomRef.child('gameState').update({
          'gameEnded': true,
          'winner': lastConnectedPlayerId,
          'winReason': 'abandonment',
          'lastMessage': 'Victoria por abandono del oponente',
          'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('🏆 Victoria automática asignada a $lastConnectedPlayerId por abandono');
      }
    } catch (e) {
      print('❌ Error verificando auto-victoria: $e');
    }
  }



  // Verificar y limpiar sala vacía
  Future<void> _checkEmptyRoom(String roomCode) async {
    try {
      final roomRef = _database!.ref('gameRooms/$roomCode');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) return;
      
      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) return;
      
      final data = Map<String, dynamic>.from(rawData);
      final playersDataRaw = data['players'];
      
      // Verificar si playersData es un Map válido
      Map<String, dynamic>? playersData;
      if (playersDataRaw is Map) {
        playersData = Map<String, dynamic>.from(playersDataRaw);
      }
      
      // Verificar si hay jugadores conectados
      bool hasConnectedPlayers = false;
      if (playersData != null) {
        for (final playerData in playersData.values) {
          if (playerData is! Map) continue;
          
          final player = Map<String, dynamic>.from(playerData);
          final isConnected = player['isConnected'] as bool? ?? true;
          if (isConnected) {
            hasConnectedPlayers = true;
            break;
          }
        }
      }
      
      // Si no hay jugadores conectados, eliminar sala
      if (!hasConnectedPlayers) {
        final isPublic = data['isPublic'] as bool? ?? false;
        
        // Eliminar de salas públicas si es pública
        if (isPublic) {
          await _database!.ref('publicRooms/$roomCode').remove();
        }
        
        // Eliminar sala
        await roomRef.remove();
        print('🧹 Sala vacía eliminada: $roomCode');
      }
    } catch (e) {
      print('❌ Error verificando sala vacía: $e');
    }
  }

  // Limpiar salas abandonadas periódicamente
  Future<void> cleanupAbandonedRooms() async {
    if (!isAvailable) return;
    
    try {
      final roomsSnapshot = await _database!.ref('gameRooms').get();
      if (!roomsSnapshot.exists) return;
      
      final rawRooms = roomsSnapshot.value;
      if (rawRooms == null || rawRooms is! Map) return;
      
      final rooms = Map<String, dynamic>.from(rawRooms);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (final entry in rooms.entries) {
        final roomCode = entry.key;
        if (entry.value is! Map) continue;
        
        final roomData = Map<String, dynamic>.from(entry.value);
        final playersDataRaw = roomData['players'];
        
        // Verificar si playersData es un Map válido
        Map<String, dynamic>? playersData;
        if (playersDataRaw is Map) {
          playersData = Map<String, dynamic>.from(playersDataRaw);
        }
        
        if (playersData == null || playersData.isEmpty) {
          await _checkEmptyRoom(roomCode);
          continue;
        }
        
        // Verificar si todos los jugadores han estado inactivos por mucho tiempo
        bool allInactive = true;
        for (final playerData in playersData.values) {
          if (playerData is! Map) continue;
          
          final player = Map<String, dynamic>.from(playerData);
          final lastHeartbeat = player['lastHeartbeat'] as int? ?? 0;
          final timeSinceLastHeartbeat = now - lastHeartbeat;
          
          // Si algún jugador ha estado activo en los últimos 5 minutos, mantener sala
          if (timeSinceLastHeartbeat < 300000) { // 5 minutos
            allInactive = false;
            break;
          }
        }
        
        if (allInactive) {
          await _checkEmptyRoom(roomCode);
        }
      }
      
      print('🧹 Limpieza de salas completada');
    } catch (e) {
      print('❌ Error en limpieza de salas: $e');
    }
  }

  // Getters
  String? get currentRoomId => _currentRoomId;
  String? get currentPlayerId => _currentPlayerId;
  bool get isInRoom => _currentRoomId != null;
}

// Extension para OnlinePlayer
extension OnlinePlayerExtension on OnlinePlayer {
  OnlinePlayer copyWith({
    String? playerId,
    String? name,
    String? avatarColor,
    String? level,
    bool? isHost,
    bool? isConnected,
  }) {
    return OnlinePlayer(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
      level: level ?? this.level,
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}