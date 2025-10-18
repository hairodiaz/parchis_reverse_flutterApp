import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

// Modelo de datos para sala de juego online
class OnlineGameRoom {
  final String roomId;
  final String hostPlayer;
  final List<OnlinePlayer> players;
  final Map<String, dynamic> gameState;
  final String status; // 'waiting', 'playing', 'finished'
  final DateTime createdAt;

  OnlineGameRoom({
    required this.roomId,
    required this.hostPlayer,
    required this.players,
    required this.gameState,
    required this.status,
    required this.createdAt,
  });

  factory OnlineGameRoom.fromMap(Map<String, dynamic> map, String roomId) {
    return OnlineGameRoom(
      roomId: roomId,
      hostPlayer: map['hostPlayer'] ?? '',
      players: (map['players'] as Map<String, dynamic>?)?.entries
          .map((e) => OnlinePlayer.fromMap(e.value, e.key))
          .toList() ?? [],
      gameState: map['gameState'] ?? {},
      status: map['status'] ?? 'waiting',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostPlayer': hostPlayer,
      'players': {
        for (var player in players) player.playerId: player.toMap()
      },
      'gameState': gameState,
      'status': status,
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
  Future<String?> createGameRoom(OnlinePlayer hostPlayer) async {
    if (!isAvailable) return null;

    try {
      final roomCode = _generateRoomCode();
      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      
      final room = OnlineGameRoom(
        roomId: roomCode,
        hostPlayer: playerId,
        players: [hostPlayer.copyWith(playerId: playerId, isHost: true)],
        gameState: {},
        status: 'waiting',
        createdAt: DateTime.now(),
      );

      await _database!.ref('gameRooms/$roomCode').set(room.toMap());
      
      _currentRoomId = roomCode;
      _currentPlayerId = playerId;
      
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
      final roomRef = _database!.ref('gameRooms/$roomCode');
      final snapshot = await roomRef.get();

      if (!snapshot.exists) {
        print('❌ Sala no encontrada: $roomCode');
        return false;
      }

      final roomData = snapshot.value as Map<String, dynamic>;
      final room = OnlineGameRoom.fromMap(roomData, roomCode);

      if (room.players.length >= 4) {
        print('❌ Sala llena: $roomCode');
        return false;
      }

      if (room.status != 'waiting') {
        print('❌ Partida ya iniciada: $roomCode');
        return false;
      }

      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      await roomRef.child('players/$playerId').set(
        player.copyWith(playerId: playerId).toMap()
      );

      _currentRoomId = roomCode;
      _currentPlayerId = playerId;

      print('✅ Unido a sala: $roomCode');
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
      if (!event.snapshot.exists) return null;
      
      final data = event.snapshot.value as Map<String, dynamic>;
      return OnlineGameRoom.fromMap(data, roomCode);
    });
  }

  // Actualizar estado del juego
  Future<void> updateGameState(String roomCode, Map<String, dynamic> gameState) async {
    if (!isAvailable) return;

    try {
      await _database!.ref('gameRooms/$roomCode/gameState').update(gameState);
    } catch (e) {
      print('❌ Error actualizando estado: $e');
    }
  }

  // Salir de la sala
  Future<void> leaveRoom() async {
    if (!isAvailable || _currentRoomId == null || _currentPlayerId == null) return;

    try {
      await _database!.ref('gameRooms/$_currentRoomId/players/$_currentPlayerId').remove();
      
      _currentRoomId = null;
      _currentPlayerId = null;
      
      print('✅ Saliste de la sala');
    } catch (e) {
      print('❌ Error saliendo de sala: $e');
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