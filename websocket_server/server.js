const WebSocket = require('ws');
const http = require('http');

// 🎮 SERVIDOR WEBSOCKET PARA PARCHIS REVERSE
// Puerto: 8080 (cambiar si es necesario)
const PORT = process.env.PORT || 8080;

// ✅ Crear servidor HTTP para Railway healthcheck
const server = http.createServer((req, res) => {
    if (req.url === '/health' || req.url === '/') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
            status: 'healthy', 
            service: 'Parchis WebSocket Server',
            timestamp: new Date().toISOString(),
            rooms: gameRooms.size,
            players: playerConnections.size
        }));
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
    }
});

// 🚀 Iniciar servidor HTTP
server.listen(PORT, () => {
    console.log(`🚀 Servidor HTTP iniciado en puerto ${PORT}`);
});

// 📡 Crear WebSocket Server sobre el servidor HTTP
const wss = new WebSocket.Server({ server });

// 📊 Estado del servidor
const gameRooms = new Map(); // roomCode -> roomData
const playerConnections = new Map(); // playerId -> {ws, roomCode, playerData}

console.log(`🚀 Servidor WebSocket iniciado en puerto ${PORT}`);
console.log(`📡 Esperando conexiones...`);

// 🏗️ Función para crear nueva sala
function createRoom(roomCode, hostData) {
    const room = {
        roomCode,
        players: new Map(),
        gameState: {
            currentPlayer: 0,
            diceValue: 0,
            pieces: [],
            gameStarted: false,
            gameEnded: false
        },
        createdAt: Date.now(),
        status: 'waiting' // waiting, playing, finished
    };
    
    gameRooms.set(roomCode, room);
    console.log(`🏠 Sala ${roomCode} creada por ${hostData.name}`);
    return room;
}

// 🧹 Función para limpiar sala vacía
function cleanupRoom(roomCode) {
    const room = gameRooms.get(roomCode);
    if (room && room.players.size === 0) {
        gameRooms.delete(roomCode);
        console.log(`🗑️ Sala ${roomCode} eliminada (vacía)`);
        return true;
    }
    return false;
}

// 📨 Función para enviar mensaje a todos en una sala
function broadcastToRoom(roomCode, message, excludePlayerId = null) {
    const room = gameRooms.get(roomCode);
    if (!room) return;
    
    room.players.forEach((playerData, playerId) => {
        if (playerId !== excludePlayerId) {
            const connection = playerConnections.get(playerId);
            if (connection && connection.ws.readyState === WebSocket.OPEN) {
                connection.ws.send(JSON.stringify(message));
            }
        }
    });
}

// 🔌 Manejar nueva conexión
wss.on('connection', (ws) => {
    let currentPlayerId = null;
    let currentRoomCode = null;
    
    console.log('👤 Nueva conexión establecida');
    
    // 📩 Manejar mensajes del cliente
    ws.on('message', (data) => {
        try {
            const message = JSON.parse(data.toString());
            console.log(`📨 Mensaje recibido:`, message.type);
            
            switch (message.type) {
                case 'join_room':
                    handleJoinRoom(message);
                    break;
                    
                case 'create_room':
                    handleCreateRoom(message);
                    break;
                    
                case 'leave_room':
                    handleLeaveRoom();
                    break;
                    
                case 'get_public_rooms':
                    handleGetPublicRooms();
                    break;
                    
                case 'game_move':
                    handleGameMove(message);
                    break;
                    
                case 'dice_roll':
                    handleDiceRoll(message);
                    break;
                    
                default:
                    console.log(`❓ Tipo de mensaje desconocido: ${message.type}`);
            }
        } catch (error) {
            console.error('❌ Error procesando mensaje:', error);
            ws.send(JSON.stringify({
                type: 'error',
                message: 'Error procesando mensaje'
            }));
        }
    });
    
    // 🏠 Crear sala
    function handleCreateRoom(message) {
        const roomCode = generateRoomCode();
        const playerId = generatePlayerId();
        const playerData = {
            id: playerId,
            name: message.playerName,
            color: message.playerColor || 'red',
            isHost: true,
            joinedAt: Date.now()
        };
        
        const room = createRoom(roomCode, playerData);
        room.players.set(playerId, playerData);
        
        currentPlayerId = playerId;
        currentRoomCode = roomCode;
        
        playerConnections.set(playerId, {
            ws,
            roomCode,
            playerData
        });
        
        ws.send(JSON.stringify({
            type: 'room_created',
            roomCode,
            playerId,
            playerData
        }));
        
        console.log(`✅ ${playerData.name} creó sala ${roomCode}`);
    }
    
    // 🚪 Unirse a sala
    function handleJoinRoom(message) {
        const { roomCode, playerName, playerColor } = message;
        const room = gameRooms.get(roomCode);
        
        if (!room) {
            ws.send(JSON.stringify({
                type: 'error',
                message: 'Sala no encontrada'
            }));
            return;
        }
        
        if (room.players.size >= 4) {
            ws.send(JSON.stringify({
                type: 'error',
                message: 'Sala llena'
            }));
            return;
        }
        
        const playerId = generatePlayerId();
        const playerData = {
            id: playerId,
            name: playerName,
            color: playerColor || 'blue',
            isHost: false,
            joinedAt: Date.now()
        };
        
        room.players.set(playerId, playerData);
        
        currentPlayerId = playerId;
        currentRoomCode = roomCode;
        
        playerConnections.set(playerId, {
            ws,
            roomCode,
            playerData
        });
        
        // Notificar al jugador que se unió
        ws.send(JSON.stringify({
            type: 'room_joined',
            roomCode,
            playerId,
            playerData,
            roomData: {
                players: Array.from(room.players.values()),
                gameState: room.gameState
            }
        }));
        
        // Notificar a otros jugadores
        broadcastToRoom(roomCode, {
            type: 'player_joined',
            playerData,
            roomData: {
                players: Array.from(room.players.values()),
                gameState: room.gameState
            }
        }, playerId);
        
        console.log(`✅ ${playerName} se unió a sala ${roomCode}`);
    }
    
    // 🚪 Salir de sala
    function handleLeaveRoom() {
        if (!currentPlayerId || !currentRoomCode) return;
        
        const room = gameRooms.get(currentRoomCode);
        if (room) {
            room.players.delete(currentPlayerId);
            
            // Notificar a otros jugadores
            broadcastToRoom(currentRoomCode, {
                type: 'player_left',
                playerId: currentPlayerId,
                roomData: {
                    players: Array.from(room.players.values()),
                    gameState: room.gameState
                }
            });
            
            console.log(`👋 Jugador ${currentPlayerId} salió de sala ${currentRoomCode}`);
            
            // Limpiar sala si está vacía
            cleanupRoom(currentRoomCode);
        }
        
        playerConnections.delete(currentPlayerId);
        currentPlayerId = null;
        currentRoomCode = null;
    }
    
    // 📋 Obtener salas públicas
    function handleGetPublicRooms() {
        console.log('📋 Solicitando salas públicas...');
        
        const publicRooms = [];
        gameRooms.forEach((room, roomCode) => {
            // Solo incluir salas en estado 'waiting' (esperando jugadores)
            if (room.status === 'waiting' && room.players.size < 4) {
                const hostPlayer = Array.from(room.players.values()).find(p => p.isHost);
                publicRooms.push({
                    roomCode,
                    hostName: hostPlayer ? hostPlayer.name : 'Host desconocido',
                    playerCount: room.players.size,
                    maxPlayers: 4,
                    status: room.status,
                    createdAt: room.createdAt
                });
            }
        });
        
        ws.send(JSON.stringify({
            type: 'public_rooms',
            rooms: publicRooms
        }));
        
        console.log(`✅ Enviadas ${publicRooms.length} salas públicas`);
    }

    // 🎲 Manejar lanzamiento de dado
    function handleDiceRoll(message) {
        if (!currentRoomCode) return;
        
        const room = gameRooms.get(currentRoomCode);
        if (!room) return;
        
        room.gameState.diceValue = message.diceValue;
        room.gameState.currentPlayer = message.currentPlayer;
        
        broadcastToRoom(currentRoomCode, {
            type: 'dice_rolled',
            diceValue: message.diceValue,
            currentPlayer: message.currentPlayer,
            playerId: currentPlayerId
        });
        
        console.log(`🎲 ${currentPlayerId} lanzó dado: ${message.diceValue}`);
    }
    
    // 🎮 Manejar movimiento de pieza
    function handleGameMove(message) {
        if (!currentRoomCode) return;
        
        const room = gameRooms.get(currentRoomCode);
        if (!room) return;
        
        // Actualizar estado del juego
        room.gameState.pieces = message.pieces;
        room.gameState.currentPlayer = message.currentPlayer;
        
        broadcastToRoom(currentRoomCode, {
            type: 'game_move',
            pieces: message.pieces,
            currentPlayer: message.currentPlayer,
            playerId: currentPlayerId
        });
        
        console.log(`🎮 ${currentPlayerId} hizo movimiento`);
    }
    
    // 🔌 Manejar desconexión
    ws.on('close', () => {
        console.log(`🔌 Conexión cerrada para jugador ${currentPlayerId}`);
        handleLeaveRoom();
    });
    
    // ❌ Manejar errores
    ws.on('error', (error) => {
        console.error('❌ Error en WebSocket:', error);
        handleLeaveRoom();
    });
});

// 🎲 Generar código de sala
function generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < 6; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

// 👤 Generar ID de jugador
function generatePlayerId() {
    return 'player_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
}

// 📊 Mostrar estadísticas cada 30 segundos
setInterval(() => {
    console.log(`📊 Estadísticas: ${gameRooms.size} salas activas, ${playerConnections.size} jugadores conectados`);
}, 30000);

// 🧹 Limpiar salas inactivas cada 5 minutos
setInterval(() => {
    const now = Date.now();
    const ROOM_TIMEOUT = 30 * 60 * 1000; // 30 minutos
    
    gameRooms.forEach((room, roomCode) => {
        if (now - room.createdAt > ROOM_TIMEOUT && room.players.size === 0) {
            gameRooms.delete(roomCode);
            console.log(`🗑️ Sala ${roomCode} eliminada por inactividad`);
        }
    });
}, 5 * 60 * 1000);