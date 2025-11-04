import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // ✅ AGREGAR para JSON

class OnlineTestScreen extends StatefulWidget {
  const OnlineTestScreen({super.key});

  @override
  State<OnlineTestScreen> createState() => _OnlineTestScreenState();
}

class _OnlineTestScreenState extends State<OnlineTestScreen> {
  String _connectionStatus = 'Desconectado';
  final List<String> _messages = [];
  final TextEditingController _roomCodeController = TextEditingController();
  WebSocket? _socket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        title: const Text('🌐 Prueba Online'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado de conexión
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _connectionStatus == 'Conectado' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Estado: $_connectionStatus',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // URL del servidor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🌐 Servidor: wss://parchisreverseflutterapp-production.up.railway.app',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de prueba
            ElevatedButton(
              onPressed: _connectToServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('🔌 Conectar al Servidor', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roomCodeController,
                    decoration: const InputDecoration(
                      hintText: 'Código de sala (ej: TEST123)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _createRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crear'),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('🚪 Unirse a Sala', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testDice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('🎲 Lanzar Dado de Prueba', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 20),
            
            // Log de mensajes
            const Text(
              '📨 Mensajes del Servidor:',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 10),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _messages[index],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _clearMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('🗑️ Limpiar Log'),
            ),
          ],
        ),
      ),
    );
  }

  void _connectToServer() async {
    try {
      setState(() {
        _connectionStatus = 'Conectando...';
        _messages.add('${DateTime.now().toString().substring(11, 19)}: Intentando conectar al servidor...');
      });
      
      _socket = await WebSocket.connect('wss://parchisreverseflutterapp-production.up.railway.app');
      
      setState(() {
        _connectionStatus = 'Conectado';
        _messages.add('${DateTime.now().toString().substring(11, 19)}: ✅ ¡Conectado exitosamente!');
      });
      
      // Escuchar mensajes del servidor
      _socket!.listen(
        (message) {
          try {
            final decoded = jsonDecode(message);
            setState(() {
              _messages.add('${DateTime.now().toString().substring(11, 19)}: 📨 ${decoded['type']}: ${decoded.toString()}');
            });
          } catch (e) {
            setState(() {
              _messages.add('${DateTime.now().toString().substring(11, 19)}: 📨 Raw: $message');
            });
          }
        },
        onError: (error) {
          setState(() {
            _connectionStatus = 'Error';
            _messages.add('${DateTime.now().toString().substring(11, 19)}: ❌ Error: $error');
          });
        },
        onDone: () {
          setState(() {
            _connectionStatus = 'Desconectado';
            _messages.add('${DateTime.now().toString().substring(11, 19)}: 🔌 Conexión cerrada');
          });
        },
      );
      
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error';
        _messages.add('${DateTime.now().toString().substring(11, 19)}: ❌ Error de conexión: $e');
      });
    }
  }

  void _createRoom() {
    if (_socket != null) {
      if (_roomCodeController.text.isEmpty) {
        _roomCodeController.text = 'TEST${DateTime.now().millisecondsSinceEpoch % 1000}';
      }
      
      final message = {
        'type': 'create_room',
        'playerName': 'TestPlayer',
        'playerColor': 'red'
      };
      
      _socket!.add(jsonEncode(message)); // ✅ Enviar como JSON
      
      setState(() {
        _messages.add('${DateTime.now().toString().substring(11, 19)}: 🏠 Creando sala...');
      });
    } else {
      setState(() {
        _messages.add('${DateTime.now().toString().substring(11, 19)}: ❌ Conéctate primero');
      });
    }
  }

  void _joinRoom() {
    if (_socket != null && _roomCodeController.text.isNotEmpty) {
      final message = {
        'type': 'join_room',
        'roomCode': _roomCodeController.text,
        'playerName': 'TestPlayer2',
        'playerColor': 'blue'
      };
      
      _socket!.add(jsonEncode(message)); // ✅ Enviar como JSON
      
      setState(() {
        _messages.add('${DateTime.now().toString().substring(11, 19)}: 🚪 Uniéndose a sala: ${_roomCodeController.text}');
      });
    } else {
      setState(() {
        _messages.add('${DateTime.now().toString().substring(11, 19)}: ❌ Conéctate primero e ingresa código de sala');
      });
    }
  }

  void _testDice() {
    if (_socket != null) {
      final diceValue = DateTime.now().millisecond % 6 + 1;
      final message = {
        'type': 'dice_roll',
        'diceValue': diceValue,
        'currentPlayer': 0
      };
      
      _socket!.add(jsonEncode(message)); // ✅ Enviar como JSON
      
      setState(() {
        _messages.add('${DateTime.now().toString().substring(11, 19)}: 🎲 Lanzando dado: $diceValue');
      });
    } else {
      setState(() {
        _messages.add('${DateTime.now().toString().substring(11, 19)}: ❌ Conéctate primero');
      });
    }
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  void dispose() {
    _socket?.close();
    _roomCodeController.dispose();
    super.dispose();
  }
}