#!/usr/bin/env python3
"""
🐍 SERVIDOR WEBSOCKET PARA PARCHIS REVERSE (PYTHON)
Alternativa a Node.js si hay problemas de instalación
"""

import asyncio
import websockets
import json
import logging
from datetime import datetime
import uuid

# Configurar logging
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

# 📊 Estado del servidor
game_rooms = {}  # roomCode -> roomData
player_connections = {}  # playerId -> {websocket, roomCode, playerData}

class GameRoom:
    def __init__(self, room_code, host_data):
        self.room_code = room_code
        self.players = {}  # playerId -> playerData
        self.game_state = {
            'current_player': 0,
            'dice_value': 0,
            'pieces': [],
            'game_started': False,
            'game_ended': False
        }
        self.created_at = datetime.now()
        self.status = 'waiting'  # waiting, playing, finished
        
        # Agregar host
        self.players[host_data['id']] = host_data
        logger.info(f"🏠 Sala {room_code} creada por {host_data['name']}")

def generate_room_code():
    """Generar código de sala"""
    import random
    import string
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

def generate_player_id():
    """Generar ID de jugador"""
    return f"player_{int(datetime.now().timestamp())}_{uuid.uuid4().hex[:8]}"

async def broadcast_to_room(room_code, message, exclude_player_id=None):
    """Enviar mensaje a todos en una sala"""
    if room_code not in game_rooms:
        return
    
    room = game_rooms[room_code]
    for player_id in room.players:
        if player_id != exclude_player_id and player_id in player_connections:
            connection = player_connections[player_id]
            try:
                await connection['websocket'].send(json.dumps(message))
            except websockets.exceptions.ConnectionClosed:
                logger.info(f"🔌 Conexión cerrada para jugador {player_id}")
                await handle_player_disconnect(player_id)

def cleanup_room(room_code):
    """Limpiar sala vacía"""
    if room_code in game_rooms:
        room = game_rooms[room_code]
        if len(room.players) == 0:
            del game_rooms[room_code]
            logger.info(f"🗑️ Sala {room_code} eliminada (vacía)")
            return True
    return False

async def handle_player_disconnect(player_id):
    """Manejar desconexión de jugador"""
    if player_id not in player_connections:
        return
    
    connection = player_connections[player_id]
    room_code = connection.get('room_code')
    
    if room_code and room_code in game_rooms:
        room = game_rooms[room_code]
        player_name = room.players.get(player_id, {}).get('name', 'Desconocido')
        
        # Remover jugador de la sala
        if player_id in room.players:
            del room.players[player_id]
            
        # Notificar a otros jugadores
        await broadcast_to_room(room_code, {
            'type': 'player_left',
            'player_id': player_id,
            'room_data': {
                'players': list(room.players.values()),
                'game_state': room.game_state
            }
        })
        
        logger.info(f"👋 {player_name} salió de sala {room_code}")
        
        # Limpiar sala si está vacía
        cleanup_room(room_code)
    
    # Remover conexión
    if player_id in player_connections:
        del player_connections[player_id]

async def handle_message(websocket, path):
    """Manejar conexión WebSocket"""
    current_player_id = None
    current_room_code = None
    
    logger.info("👤 Nueva conexión establecida")
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                msg_type = data.get('type')
                logger.info(f"📨 Mensaje recibido: {msg_type}")
                
                if msg_type == 'create_room':
                    # Crear nueva sala
                    room_code = generate_room_code()
                    player_id = generate_player_id()
                    
                    player_data = {
                        'id': player_id,
                        'name': data.get('playerName', 'Jugador'),
                        'color': data.get('playerColor', 'red'),
                        'is_host': True,
                        'joined_at': int(datetime.now().timestamp() * 1000)
                    }
                    
                    # Crear sala
                    room = GameRoom(room_code, player_data)
                    game_rooms[room_code] = room
                    
                    # Registrar conexión
                    current_player_id = player_id
                    current_room_code = room_code
                    player_connections[player_id] = {
                        'websocket': websocket,
                        'room_code': room_code,
                        'player_data': player_data
                    }
                    
                    # Responder al cliente
                    await websocket.send(json.dumps({
                        'type': 'room_created',
                        'roomCode': room_code,
                        'playerId': player_id,
                        'playerData': player_data
                    }))
                    
                    logger.info(f"✅ {player_data['name']} creó sala {room_code}")
                
                elif msg_type == 'join_room':
                    # Unirse a sala
                    room_code = data.get('roomCode')
                    player_name = data.get('playerName', 'Jugador')
                    
                    if room_code not in game_rooms:
                        await websocket.send(json.dumps({
                            'type': 'error',
                            'message': 'Sala no encontrada'
                        }))
                        continue
                    
                    room = game_rooms[room_code]
                    
                    if len(room.players) >= 4:
                        await websocket.send(json.dumps({
                            'type': 'error',
                            'message': 'Sala llena'
                        }))
                        continue
                    
                    # Crear jugador
                    player_id = generate_player_id()
                    player_data = {
                        'id': player_id,
                        'name': player_name,
                        'color': data.get('playerColor', 'blue'),
                        'is_host': False,
                        'joined_at': int(datetime.now().timestamp() * 1000)
                    }
                    
                    # Agregar a sala
                    room.players[player_id] = player_data
                    
                    # Registrar conexión
                    current_player_id = player_id
                    current_room_code = room_code
                    player_connections[player_id] = {
                        'websocket': websocket,
                        'room_code': room_code,
                        'player_data': player_data
                    }
                    
                    # Responder al cliente
                    await websocket.send(json.dumps({
                        'type': 'room_joined',
                        'roomCode': room_code,
                        'playerId': player_id,
                        'playerData': player_data,
                        'roomData': {
                            'players': list(room.players.values()),
                            'gameState': room.game_state
                        }
                    }))
                    
                    # Notificar a otros jugadores
                    await broadcast_to_room(room_code, {
                        'type': 'player_joined',
                        'playerData': player_data,
                        'roomData': {
                            'players': list(room.players.values()),
                            'gameState': room.game_state
                        }
                    }, player_id)
                    
                    logger.info(f"✅ {player_name} se unió a sala {room_code}")
                
                elif msg_type == 'leave_room':
                    # Salir de sala
                    if current_player_id:
                        await handle_player_disconnect(current_player_id)
                        current_player_id = None
                        current_room_code = None
                
                elif msg_type == 'dice_roll':
                    # Lanzar dado
                    if current_room_code and current_room_code in game_rooms:
                        room = game_rooms[current_room_code]
                        room.game_state['dice_value'] = data.get('diceValue', 0)
                        room.game_state['current_player'] = data.get('currentPlayer', 0)
                        
                        await broadcast_to_room(current_room_code, {
                            'type': 'dice_rolled',
                            'diceValue': data.get('diceValue', 0),
                            'currentPlayer': data.get('currentPlayer', 0),
                            'playerId': current_player_id
                        })
                        
                        logger.info(f"🎲 {current_player_id} lanzó dado: {data.get('diceValue', 0)}")
                
                elif msg_type == 'game_move':
                    # Movimiento de pieza
                    if current_room_code and current_room_code in game_rooms:
                        room = game_rooms[current_room_code]
                        room.game_state['pieces'] = data.get('pieces', [])
                        room.game_state['current_player'] = data.get('currentPlayer', 0)
                        
                        await broadcast_to_room(current_room_code, {
                            'type': 'game_move',
                            'pieces': data.get('pieces', []),
                            'currentPlayer': data.get('currentPlayer', 0),
                            'playerId': current_player_id
                        })
                        
                        logger.info(f"🎮 {current_player_id} hizo movimiento")
                
                else:
                    logger.info(f"❓ Tipo de mensaje desconocido: {msg_type}")
                    
            except json.JSONDecodeError:
                logger.error("❌ Error decodificando JSON")
            except Exception as e:
                logger.error(f"❌ Error procesando mensaje: {e}")
                
    except websockets.exceptions.ConnectionClosed:
        logger.info("🔌 Conexión WebSocket cerrada")
    except Exception as e:
        logger.error(f"❌ Error en WebSocket: {e}")
    finally:
        # Limpiar al desconectar
        if current_player_id:
            await handle_player_disconnect(current_player_id)

async def stats_logger():
    """Mostrar estadísticas cada 30 segundos"""
    while True:
        await asyncio.sleep(30)
        rooms_count = len(game_rooms)
        players_count = len(player_connections)
        logger.info(f"📊 Estadísticas: {rooms_count} salas activas, {players_count} jugadores conectados")

async def cleanup_inactive_rooms():
    """Limpiar salas inactivas cada 5 minutos"""
    while True:
        await asyncio.sleep(300)  # 5 minutos
        current_time = datetime.now()
        rooms_to_delete = []
        
        for room_code, room in game_rooms.items():
            # Eliminar salas de más de 30 minutos sin jugadores
            if len(room.players) == 0:
                time_diff = (current_time - room.created_at).total_seconds()
                if time_diff > 1800:  # 30 minutos
                    rooms_to_delete.append(room_code)
        
        for room_code in rooms_to_delete:
            del game_rooms[room_code]
            logger.info(f"🗑️ Sala {room_code} eliminada por inactividad")

def main():
    """Función principal"""
    print("🐍 SERVIDOR WEBSOCKET PARCHIS REVERSE (PYTHON)")
    print(f"🚀 Iniciando servidor en puerto 8080...")
    
    # Iniciar servidor
    start_server = websockets.serve(handle_message, "localhost", 8080)
    
    # Obtener bucle de eventos
    loop = asyncio.get_event_loop()
    
    # Programar tareas de mantenimiento
    loop.create_task(stats_logger())
    loop.create_task(cleanup_inactive_rooms())
    
    print(f"✅ Servidor WebSocket iniciado en puerto 8080")
    print(f"📡 Esperando conexiones...")
    
    try:
        loop.run_until_complete(start_server)
        loop.run_forever()
    except KeyboardInterrupt:
        print("\n🛑 Cerrando servidor...")
    except Exception as e:
        print(f"❌ Error del servidor: {e}")

if __name__ == "__main__":
    main()