import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';
import 'dart:async';

// Modelo de estado del juego online MEJORADO
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
  final int sequenceNumber; // Para validación autoritativa
  final String? authorityPlayerId; // Quién realizó el último cambio

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
    this.sequenceNumber = 0,
    this.authorityPlayerId,
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
        sequenceNumber: map['sequenceNumber'] ?? 0,
        authorityPlayerId: map['authorityPlayerId'],
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
      'sequenceNumber': sequenceNumber,
      'authorityPlayerId': authorityPlayerId,
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
    int? sequenceNumber,
    String? authorityPlayerId,
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
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      authorityPlayerId: authorityPlayerId ?? this.authorityPlayerId,
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
  
  // 🚀 SISTEMA DE BATCHING PARA OPTIMIZACIÓN
  Timer? _batchUpdateTimer;
  Map<String, dynamic> _pendingUpdates = {};
  bool _isBatchUpdateInProgress = false;

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
    // 🔍 LOGGING DETALLADO PARA RASTREAR CREACIÓN AUTOMÁTICA
    print('🏗️ ========== CREATEROOM LLAMADO ==========');
    print('🏗️ Host: ${hostPlayer.name}');
    print('🏗️ Público: $isPublic');
    print('🏗️ Timestamp: ${DateTime.now()}');
    print('🏗️ Stack trace:');
    print(StackTrace.current);
    print('🏗️ =====================================');
    
    if (!isAvailable) {
      print('❌ Firebase no disponible para crear sala');
      return null;
    }

    try {
      final roomCode = _generateRoomCode();
      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      
      print('✅ Creando sala con código: $roomCode');
      
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

      // 🔍 VERIFICAR SI EL JUGADOR YA ESTÁ EN LA SALA (EVITAR DUPLICADOS)
      bool playerAlreadyExists = false;
      String? existingPlayerId;
      
      for (final existingPlayer in room.players) {
        if (existingPlayer.name == player.name || 
            existingPlayer.playerId == player.playerId) {
          playerAlreadyExists = true;
          existingPlayerId = existingPlayer.playerId;
          print('⚠️ Jugador ${player.name} ya está en la sala como ${existingPlayerId}');
          break;
        }
      }

      if (playerAlreadyExists && existingPlayerId != null) {
        // Actualizar información del jugador existente en lugar de crear duplicado
        await roomRef.child('players/$existingPlayerId').update({
          'lastHeartbeat': DateTime.now().millisecondsSinceEpoch,
          'isConnected': true,
          'rejoinedAt': DateTime.now().millisecondsSinceEpoch,
        });

        _currentRoomId = normalizedCode;
        _currentPlayerId = existingPlayerId;

        print('🔄 Jugador ${player.name} reconectado a sala: $normalizedCode');
        _startHeartbeat();
        return true;
      }

      // Si no existe, crear nuevo jugador
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
      
      // 🧹 CLEANUP COMPLETO para evitar creaciones automáticas
      cleanupCompletely();
      
    } catch (e) {
      print('❌ Error saliendo de sala pre-partida: $e');
      // 🧹 Cleanup incluso si hay error
      cleanupCompletely();
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

  // 💥 NUEVA FUNCIÓN: Sincronizar captura de fichas
  Future<bool> capturePiece(String roomCode, OnlineGamePiece attacker, OnlineGamePiece victim, String message) async {
    if (!isAvailable || roomCode.isEmpty) return false;

    try {
      print('💥 Sincronizando captura: ${attacker.color} captura a ${victim.color}');
      
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

      // Actualizar fichas: atacante mantiene posición, víctima va a SALIDA (9,0)
      final updatedPieces = currentState.pieces.map((p) {
        if (p.id == victim.id && p.playerIndex == victim.playerIndex) {
          print('🏠 Enviando ${victim.color} a SALIDA');
          return OnlineGamePiece(
            id: victim.id,
            playerIndex: victim.playerIndex,
            color: victim.color,
            row: 9, // SALIDA
            col: 0, // SALIDA
          );
        } else if (p.id == attacker.id && p.playerIndex == attacker.playerIndex) {
          print('👑 ${attacker.color} permanece en posición (${attacker.row},${attacker.col})');
          return attacker; // Mantener la posición del atacante
        }
        return p;
      }).toList();

      await _database!.ref('gameRooms/$roomCode/gameState').update({
        'pieces': updatedPieces.map((p) => p.toMap()).toList(),
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        'lastMessage': message,
        'isMoving': false,
      });

      print('✅ Captura sincronizada exitosamente en sala $roomCode');
      return true;
    } catch (e) {
      print('❌ Error sincronizando captura: $e');
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

  // Sistema de detección de abandono MEJORADO
  void _startHeartbeat() {
    if (_currentRoomId == null || _currentPlayerId == null) {
      print('⚠️ _startHeartbeat: Sin roomId o playerId, cancelando');
      return;
    }
    
    print('💓 Iniciando heartbeat para sala $_currentRoomId, jugador $_currentPlayerId');
    
    _heartbeatTimer?.cancel();
    _abandonmentCheckTimer?.cancel();
    
    // Heartbeat más frecuente para mejor detección: cada 5 segundos
    _heartbeatTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      print('💓 Ejecutando heartbeat para sala $_currentRoomId');
      try {
        await _database!.ref('gameRooms/$_currentRoomId/players/$_currentPlayerId').update({
          'lastHeartbeat': DateTime.now().millisecondsSinceEpoch,
          'isConnected': true,
          'lastActivity': DateTime.now().millisecondsSinceEpoch, // Nueva marca de actividad
        });
      } catch (e) {
        print('❌ Error en heartbeat: $e');
        // Si hay error de conexión, reintentar en el próximo ciclo
      }
    });
    
    // Verificar abandono más frecuente: cada 8 segundos
    _abandonmentCheckTimer = Timer.periodic(Duration(seconds: 8), (timer) async {
      print('🔍 Ejecutando checkPlayerAbandonment para sala $_currentRoomId');
      await checkPlayerAbandonment();
    });
    
    // Limpieza de salas cada 2 minutos (solo una instancia)
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(Duration(minutes: 2), (timer) async {
      await cleanupAbandonedRooms();
    });
    
    print('💓 Sistema de heartbeat mejorado iniciado - detección cada 5s');
  }

  // 🚀 SISTEMA DE BATCHING PARA REDUCIR LAG
  void _queueUpdate(String roomCode, Map<String, dynamic> updates) {
    if (!isAvailable || roomCode.isEmpty) return;
    
    // Agregar actualizaciones al batch pendiente
    _pendingUpdates.addAll(updates);
    
    // Cancelar timer anterior y crear uno nuevo
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(Duration(milliseconds: 100), () async {
      await _processBatchUpdates(roomCode);
    });
  }
  
  Future<void> _processBatchUpdates(String roomCode) async {
    if (_isBatchUpdateInProgress || _pendingUpdates.isEmpty) return;
    
    _isBatchUpdateInProgress = true;
    final updatesToProcess = Map<String, dynamic>.from(_pendingUpdates);
    _pendingUpdates.clear();
    
    try {
      // Aplicar todas las actualizaciones en una sola operación
      await _database!.ref('gameRooms/$roomCode/gameState').update(updatesToProcess);
      print('⚡ Batch actualizado: ${updatesToProcess.keys.join(', ')}');
    } catch (e) {
      print('❌ Error en batch update: $e');
    } finally {
      _isBatchUpdateInProgress = false;
    }
  }

  // Función optimizada para movimiento de piezas con batching
  Future<bool> moveOrCapturePiece(String roomCode, OnlineGamePiece piece, {OnlineGamePiece? capturedPiece, String? captureMessage}) async {
    if (!isAvailable || roomCode.isEmpty) return false;

    try {
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

      // Actualizar las piezas
      final updatedPieces = currentState.pieces.map((p) {
        // Actualizar la pieza que se movió
        if (p.id == piece.id && p.playerIndex == piece.playerIndex) {
          return piece;
        }
        // Si hay captura, enviar la víctima a SALIDA
        if (capturedPiece != null && p.id == capturedPiece.id && p.playerIndex == capturedPiece.playerIndex) {
          return OnlineGamePiece(
            id: capturedPiece.id,
            playerIndex: capturedPiece.playerIndex,
            color: capturedPiece.color,
            row: 9, // SALIDA
            col: 0, // SALIDA
          );
        }
        return p;
      }).toList();

      // 🛡️ VALIDACIÓN AUTORITATIVA: Preparar actualizaciones con secuencia
      final nextSequence = currentState.sequenceNumber + 1;
      final updates = <String, dynamic>{
        'pieces': updatedPieces.map((p) => p.toMap()).toList(),
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        'isMoving': false,
        'sequenceNumber': nextSequence,
        'authorityPlayerId': _currentPlayerId,
      };
      
      if (captureMessage != null) {
        updates['lastMessage'] = captureMessage;
      }

      // Usar sistema de batching para reducir lag
      _queueUpdate(roomCode, updates);
      
      print(capturedPiece != null 
        ? '💥 Captura ${piece.color} → ${capturedPiece.color} [Seq: $nextSequence]' 
        : '🔄 Movimiento ${piece.color} a (${piece.row},${piece.col}) [Seq: $nextSequence]');
      
      return true;
    } catch (e) {
      print('❌ Error en moveOrCapturePiece: $e');
      return false;
    }
  }

  // 🛡️ VALIDACIÓN DE ESTADO AUTORITATIVO
  bool isValidStateTransition(OnlineGameState currentState, OnlineGameState newState) {
    // Verificar secuencia monotónica
    if (newState.sequenceNumber <= currentState.sequenceNumber) {
      print('⚠️ Secuencia inválida: ${newState.sequenceNumber} <= ${currentState.sequenceNumber}');
      return false;
    }
    
    // Verificar que el tiempo es posterior
    if (newState.lastUpdate.isBefore(currentState.lastUpdate)) {
      print('⚠️ Timestamp inválido: estado más antiguo que el actual');
      return false;
    }
    
    // Si el juego ya terminó, no permitir más cambios
    if (currentState.gameEnded && !newState.gameEnded) {
      print('⚠️ Intento de revertir juego terminado');
      return false;
    }
    
    return true;
  }

  // Resolución de conflictos basada en autoridad
  OnlineGameState resolveConflict(OnlineGameState local, OnlineGameState remote) {
    print('🔧 Resolviendo conflicto de estado...');
    
    // El estado con mayor secuencia gana
    if (remote.sequenceNumber > local.sequenceNumber) {
      print('📡 Estado remoto es más reciente (${remote.sequenceNumber} > ${local.sequenceNumber})');
      return remote;
    } else if (local.sequenceNumber > remote.sequenceNumber) {
      print('📱 Estado local es más reciente (${local.sequenceNumber} > ${remote.sequenceNumber})');
      return local;
    } else {
      // En caso de empate, usar timestamp
      if (remote.lastUpdate.isAfter(local.lastUpdate)) {
        print('⏰ Estado remoto es más reciente por timestamp');
        return remote;
      } else {
        print('⏰ Estado local es más reciente por timestamp');
        return local;
      }
    }
  }

  void _stopHeartbeat() {
    print('🛑 Deteniendo heartbeat y todos los timers');
    print('🛑 RoomId actual: $_currentRoomId');
    print('🛑 PlayerId actual: $_currentPlayerId');
    
    _heartbeatTimer?.cancel();
    _abandonmentCheckTimer?.cancel();
    _cleanupTimer?.cancel();
    _batchUpdateTimer?.cancel();
    _heartbeatTimer = null;
    _abandonmentCheckTimer = null;
    _cleanupTimer = null;
    _batchUpdateTimer = null;
    _pendingUpdates.clear();
    _isBatchUpdateInProgress = false;
    
    print('✅ Todos los timers cancelados');
  }

  // 🧹 MÉTODO PARA LIMPIAR COMPLETAMENTE EL SERVICIO
  void cleanupCompletely() {
    print('🧹 ========== CLEANUP COMPLETO ==========');
    print('🧹 Estado antes: RoomId=$_currentRoomId, PlayerId=$_currentPlayerId');
    
    // Cancelar todos los timers
    _stopHeartbeat();
    
    // Limpiar todas las referencias
    _currentRoomId = null;
    _currentPlayerId = null;
    
    print('🧹 Estado después: RoomId=$_currentRoomId, PlayerId=$_currentPlayerId');
    print('🧹 ===================================');
  }

  // 🧹 MÉTODO ESTÁTICO PARA LIMPIAR DESDE CUALQUIER PARTE
  static void globalCleanup() {
    print('🌐 ========== CLEANUP GLOBAL ==========');
    final instance = FirebaseService();
    instance.cleanupCompletely();
    print('🌐 ==================================');
  }

  // Verificar abandono de jugadores MEJORADO
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
      final gameStateRaw = data['gameState'];
      
      // Verificar si es una partida activa
      bool isGameActive = false;
      if (gameStateRaw is Map) {
        final gameState = Map<String, dynamic>.from(gameStateRaw);
        final status = data['status'] as String? ?? 'waiting';
        final gameEnded = gameState['gameEnded'] as bool? ?? false;
        isGameActive = (status == 'playing') && !gameEnded;
      }
      
      // Verificar si playersData es un Map válido
      Map<String, dynamic>? playersData;
      if (playersDataRaw is Map) {
        playersData = Map<String, dynamic>.from(playersDataRaw);
      }
      
      if (playersData == null) return;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      // Timeout más estricto durante partida activa
      final timeoutMs = isGameActive ? 20000 : 30000; // 20s en partida, 30s en espera
      
      for (final entry in playersData.entries) {
        if (entry.value is! Map) continue;
        
        final playerData = Map<String, dynamic>.from(entry.value as Map);
        final lastHeartbeat = playerData['lastHeartbeat'] as int? ?? 0;
        final isConnected = playerData['isConnected'] as bool? ?? true;
        
        // Si el jugador no ha enviado heartbeat en el tiempo límite
        if (isConnected && (now - lastHeartbeat) > timeoutMs) {
          await roomRef.child('players/${entry.key}').update({
            'isConnected': false,
            'disconnectedAt': now,
          });
          
          final playerName = playerData['name'] as String? ?? 'Jugador ${entry.key}';
          print('⚠️ $playerName desconectado por inactividad (${isGameActive ? 'PARTIDA ACTIVA' : 'SALA DE ESPERA'})');
          
          // Si es partida activa, otorgar victoria inmediatamente
          if (isGameActive) {
            await _checkAutoVictory();
          }
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
      final gameStateRaw = data['gameState'];
      
      // Verificar si playersData es un Map válido
      Map<String, dynamic>? playersData;
      if (playersDataRaw is Map) {
        playersData = Map<String, dynamic>.from(playersDataRaw);
      }
      
      if (playersData == null) return;
      
      // Verificar si el juego ya terminó
      if (gameStateRaw is Map) {
        final gameState = Map<String, dynamic>.from(gameStateRaw);
        final gameEnded = gameState['gameEnded'] as bool? ?? false;
        if (gameEnded) {
          print('🎮 Juego ya terminado, evitando auto-victoria duplicada');
          return;
        }
      }
      
      // Contar jugadores conectados
      int connectedPlayers = 0;
      String? lastConnectedPlayerId;
      String? lastConnectedPlayerName;
      
      for (final entry in playersData.entries) {
        if (entry.value is! Map) continue;
        
        final playerData = Map<String, dynamic>.from(entry.value as Map);
        final isConnected = playerData['isConnected'] as bool? ?? true;
        
        if (isConnected) {
          connectedPlayers++;
          lastConnectedPlayerId = entry.key;
          lastConnectedPlayerName = playerData['name'] as String? ?? 'Jugador ${entry.key}';
        }
      }
      
      // Si solo queda un jugador conectado, declarar victoria automática
      if (connectedPlayers == 1 && lastConnectedPlayerId != null) {
        final victoryMessage = '$lastConnectedPlayerName gana por abandono del oponente! 🏆';
        
        await roomRef.child('gameState').update({
          'gameEnded': true,
          'winner': lastConnectedPlayerName,
          'winReason': 'abandonment',
          'lastMessage': victoryMessage,
          'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        });
        
        // También actualizar el estado de la sala
        await roomRef.update({
          'status': 'finished',
          'endedAt': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('🏆 Victoria automática: $lastConnectedPlayerName gana por abandono');
      } else if (connectedPlayers == 0) {
        // Si no quedan jugadores conectados, cerrar la sala
        await roomRef.update({
          'status': 'abandoned',
          'endedAt': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('🚪 Sala abandonada por todos los jugadores');
      }
    } catch (e) {
      print('❌ Error verificando auto-victoria: $e');
    }
  }



  // Verificar y limpiar sala vacía
  // 🧹 MEJORADO: Verificar y limpiar sala vacía
  Future<void> _checkEmptyRoom(String roomCode) async {
    try {
      final roomRef = _database!.ref('gameRooms/$roomCode');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) {
        print('🔍 Sala $roomCode ya no existe');
        return;
      }
      
      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) {
        print('🔍 Datos inválidos en sala $roomCode');
        await roomRef.remove();
        return;
      }
      
      final data = Map<String, dynamic>.from(rawData);
      final playersDataRaw = data['players'];
      final status = data['status'] as String? ?? 'waiting';
      
      // Verificar si playersData es un Map válido
      Map<String, dynamic>? playersData;
      if (playersDataRaw is Map) {
        playersData = Map<String, dynamic>.from(playersDataRaw);
      }
      
      // Contar jugadores reales y conectados
      int totalPlayers = playersData?.length ?? 0;
      int connectedPlayers = 0;
      
      if (playersData != null) {
        for (final playerData in playersData.values) {
          if (playerData is! Map) continue;
          
          final player = Map<String, dynamic>.from(playerData);
          final isConnected = player['isConnected'] as bool? ?? true;
          if (isConnected) {
            connectedPlayers++;
          }
        }
      }
      
      print('🔍 Verificando sala $roomCode: $connectedPlayers/$totalPlayers jugadores conectados (Status: $status)');
      
      // Decidir si eliminar la sala
      bool shouldDeleteRoom = false;
      String deleteReason = '';
      
      if (totalPlayers == 0) {
        shouldDeleteRoom = true;
        deleteReason = 'No hay jugadores en la sala';
      } else if (connectedPlayers == 0) {
        shouldDeleteRoom = true;
        deleteReason = 'Todos los jugadores desconectados';
      } else if (status == 'deleted') {
        shouldDeleteRoom = true;
        deleteReason = 'Sala marcada para eliminación';
      }
      
      if (shouldDeleteRoom) {
        final isPublic = data['isPublic'] as bool? ?? false;
        
        // Eliminar de salas públicas si es pública
        if (isPublic) {
          await _database!.ref('publicRooms/$roomCode').remove();
          print('🗑️ Eliminada de salas públicas: $roomCode');
        }
        
        // Eliminar sala completa
        await roomRef.remove();
        print('🗑️ Sala $roomCode eliminada: $deleteReason');
      } else {
        print('✅ Sala $roomCode mantenida: $connectedPlayers jugadores activos');
      }
    } catch (e) {
      print('❌ Error verificando sala vacía: $e');
    }
  }

  // 🧹 LIMPIEZA MEJORADA DE SALAS ABANDONADAS
  Future<void> cleanupAbandonedRooms() async {
    if (!isAvailable) return;
    
    try {
      final roomsSnapshot = await _database!.ref('gameRooms').get();
      if (!roomsSnapshot.exists) return;
      
      final rawRooms = roomsSnapshot.value;
      if (rawRooms == null || rawRooms is! Map) return;
      
      final rooms = Map<String, dynamic>.from(rawRooms);
      final now = DateTime.now().millisecondsSinceEpoch;
      int roomsCleaned = 0;
      
      for (final entry in rooms.entries) {
        final roomCode = entry.key;
        if (entry.value is! Map) continue;
        
        final roomData = Map<String, dynamic>.from(entry.value);
        final playersDataRaw = roomData['players'];
        final status = roomData['status'] as String? ?? 'waiting';
        final createdAt = roomData['createdAt'] as int? ?? 0;
        
        // 🗑️ CRITERIOS DE LIMPIEZA MEJORADOS
        
        // 1. Salas sin jugadores
        if (playersDataRaw == null || (playersDataRaw is Map && playersDataRaw.isEmpty)) {
          await _deleteRoom(roomCode, 'Sin jugadores');
          roomsCleaned++;
          continue;
        }
        
        // 2. Salas muy antiguas (más de 6 horas)
        if (now - createdAt > 21600000) { // 6 horas
          await _deleteRoom(roomCode, 'Sala muy antigua');
          roomsCleaned++;
          continue;
        }
        
        // 3. Salas terminadas hace más de 1 hora
        if (status == 'finished' || status == 'abandoned') {
          final endedAt = roomData['endedAt'] as int? ?? createdAt;
          if (now - endedAt > 3600000) { // 1 hora
            await _deleteRoom(roomCode, 'Partida terminada hace tiempo');
            roomsCleaned++;
            continue;
          }
        }
        
        // 4. Verificar actividad de jugadores
        Map<String, dynamic>? playersData;
        if (playersDataRaw is Map) {
          playersData = Map<String, dynamic>.from(playersDataRaw);
        }
        
        if (playersData != null && playersData.isNotEmpty) {
          bool allInactive = true;
          int connectedPlayers = 0;
          
          for (final playerData in playersData.values) {
            if (playerData is! Map) continue;
            
            final player = Map<String, dynamic>.from(playerData);
            final lastHeartbeat = player['lastHeartbeat'] as int? ?? 0;
            final isConnected = player['isConnected'] as bool? ?? false;
            final timeSinceLastHeartbeat = now - lastHeartbeat;
            
            if (isConnected) connectedPlayers++;
            
            // Timeout más estricto para partidas activas
            final timeout = status == 'playing' ? 300000 : 600000; // 5min vs 10min
            
            if (timeSinceLastHeartbeat < timeout) {
              allInactive = false;
            }
          }
          
          // 5. Si no hay jugadores conectados en partida activa
          if (status == 'playing' && connectedPlayers == 0) {
            await _deleteRoom(roomCode, 'Partida abandonada por todos');
            roomsCleaned++;
            continue;
          }
          
          // 6. Si todos han estado inactivos por mucho tiempo
          if (allInactive && connectedPlayers == 0) {
            await _deleteRoom(roomCode, 'Todos los jugadores inactivos');
            roomsCleaned++;
            continue;
          }
        }
      }
      
      if (roomsCleaned > 0) {
        print('🧹 Limpieza completada: $roomsCleaned salas eliminadas');
      } else {
        print('🧹 Limpieza completada: No se encontraron salas para eliminar');
      }
    } catch (e) {
      print('❌ Error en limpieza de salas: $e');
    }
  }
  
  // Función auxiliar para eliminar salas con logging
  Future<void> _deleteRoom(String roomCode, String reason) async {
    try {
      await _database!.ref('gameRooms/$roomCode').remove();
      print('🗑️ Sala $roomCode eliminada: $reason');
    } catch (e) {
      print('❌ Error eliminando sala $roomCode: $e');
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