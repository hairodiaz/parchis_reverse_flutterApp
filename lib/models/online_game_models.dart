/// 🎮 MODELOS PARA JUEGO ONLINE
/// Clases para manejar datos del juego multijugador
library;

/// 👤 Modelo de jugador online
class OnlinePlayer {
  final String id;
  final String name;
  final String color;
  final bool isHost;
  final DateTime joinedAt;
  final bool isConnected;

  OnlinePlayer({
    required this.id,
    required this.name,
    required this.color,
    this.isHost = false,
    required this.joinedAt,
    this.isConnected = true,
  });

  factory OnlinePlayer.fromJson(Map<String, dynamic> json) {
    return OnlinePlayer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? 'red',
      isHost: json['isHost'] ?? false,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joinedAt'] ?? 0),
      isConnected: json['isConnected'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'isHost': isHost,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'isConnected': isConnected,
    };
  }
}

/// 🏠 Modelo de sala de juego online
class OnlineGameRoom {
  final String roomCode;
  final List<OnlinePlayer> players;
  final OnlineGameState gameState;
  final DateTime createdAt;
  final String status; // waiting, playing, finished
  final int maxPlayers;

  OnlineGameRoom({
    required this.roomCode,
    required this.players,
    required this.gameState,
    required this.createdAt,
    this.status = 'waiting',
    this.maxPlayers = 4,
  });

  factory OnlineGameRoom.fromJson(Map<String, dynamic> json) {
    return OnlineGameRoom(
      roomCode: json['roomCode'] ?? '',
      players: (json['players'] as List<dynamic>?)
          ?.map((p) => OnlinePlayer.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      gameState: OnlineGameState.fromJson(json['gameState'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      status: json['status'] ?? 'waiting',
      maxPlayers: json['maxPlayers'] ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'players': players.map((p) => p.toJson()).toList(),
      'gameState': gameState.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
      'maxPlayers': maxPlayers,
    };
  }

  bool get isFull => players.length >= maxPlayers;
  bool get isEmpty => players.isEmpty;
  bool get canStart => players.length >= 2;
  OnlinePlayer? get host => players.firstWhere((p) => p.isHost, orElse: () => players.first);
}

/// 🎮 Estado del juego online
class OnlineGameState {
  final int currentPlayer;
  final int diceValue;
  final List<OnlineGamePiece> pieces;
  final bool gameStarted;
  final bool gameEnded;
  final String? winner;
  final DateTime lastMove;

  OnlineGameState({
    this.currentPlayer = 0,
    this.diceValue = 0,
    this.pieces = const [],
    this.gameStarted = false,
    this.gameEnded = false,
    this.winner,
    DateTime? lastMove,
  }) : lastMove = lastMove ?? DateTime.now();

  factory OnlineGameState.fromJson(Map<String, dynamic> json) {
    return OnlineGameState(
      currentPlayer: json['currentPlayer'] ?? 0,
      diceValue: json['diceValue'] ?? 0,
      pieces: (json['pieces'] as List<dynamic>?)
          ?.map((p) => OnlineGamePiece.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      gameStarted: json['gameStarted'] ?? false,
      gameEnded: json['gameEnded'] ?? false,
      winner: json['winner'],
      lastMove: DateTime.fromMillisecondsSinceEpoch(json['lastMove'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPlayer': currentPlayer,
      'diceValue': diceValue,
      'pieces': pieces.map((p) => p.toJson()).toList(),
      'gameStarted': gameStarted,
      'gameEnded': gameEnded,
      'winner': winner,
      'lastMove': lastMove.millisecondsSinceEpoch,
    };
  }
}

/// 🔴 Modelo de ficha online
class OnlineGamePiece {
  final String id;
  final String playerId;
  final String color;
  final int row;
  final int col;
  final bool isAtHome;
  final bool isAtEnd;
  final int position; // Posición en el tablero (0-67)

  OnlineGamePiece({
    required this.id,
    required this.playerId,
    required this.color,
    required this.row,
    required this.col,
    this.isAtHome = true,
    this.isAtEnd = false,
    this.position = -1,
  });

  factory OnlineGamePiece.fromJson(Map<String, dynamic> json) {
    return OnlineGamePiece(
      id: json['id'] ?? '',
      playerId: json['playerId'] ?? '',
      color: json['color'] ?? 'red',
      row: json['row'] ?? 0,
      col: json['col'] ?? 0,
      isAtHome: json['isAtHome'] ?? true,
      isAtEnd: json['isAtEnd'] ?? false,
      position: json['position'] ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'color': color,
      'row': row,
      'col': col,
      'isAtHome': isAtHome,
      'isAtEnd': isAtEnd,
      'position': position,
    };
  }
}

/// 📨 Modelo de mensaje WebSocket
class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}