import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'online_waiting_room.dart';

/// 🌐 PANTALLA DE LOBBY ONLINE
/// 
/// Esta pantalla permite:
/// - 🏠 Crear nueva sala
/// - 🚪 Unirse a sala por código
/// - 📋 Ver salas públicas disponibles
/// - 🎮 Configurar nombre y color del jugador

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({Key? key}) : super(key: key);

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> 
    with TickerProviderStateMixin {
  
  // 🎮 Controladores
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  
  // 📊 Estado
  bool _isConnecting = false;
  bool _isConnected = false;
  String _selectedColor = 'red';
  int _currentTab = 0; // 0: Crear, 1: Unirse, 2: Públicas
  
  final List<Color> _playerColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];
  
  final List<String> _colorNames = ['red', 'blue', 'green', 'yellow'];

  @override
  void initState() {
    super.initState();
    
    // 🎨 Inicializar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // 🚀 Iniciar animaciones
    _fadeController.forward();
    _scaleController.forward();
    
    // 🎮 Configurar nombre inicial del jugador
    _initializePlayerName();
    
    // � Listener para actualizar botón de unirse dinámicamente
    _roomCodeController.addListener(() {
      setState(() {}); // Reconstruir para actualizar estado del botón
    });
    
    // �🔌 Auto-conectar al servidor
    _autoConnectToServer();
  }

  void _initializePlayerName() {
    final currentUser = AuthService().currentUser;
    _playerNameController.text = currentUser?.name ?? 'Jugador ${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  Future<void> _autoConnectToServer() async {
    setState(() => _isConnecting = true);
    
    try {
      // 🎯 Simulamos conexión exitosa por ahora
      // TODO: Usar WebSocketService real cuando se arreglen los modelos
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isConnected = true; // Siempre exitoso por ahora
        _isConnecting = false;
      });
      
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
      });
      _showErrorDialog('Error', 'Error inesperado: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _roomCodeController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildContent(),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 📱 Header con estado de conexión
        _buildHeader(),
        
        // 🎮 Configuración del jugador
        _buildPlayerConfig(),
        
        // 📋 Tabs de opciones
        _buildTabSelector(),
        
        // 📄 Contenido del tab actual
        Expanded(child: _buildTabContent()),
        
        // 🔙 Botón de volver
        _buildBackButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 🎮 Título
          const Text(
            '🌐 LOBBY ONLINE',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 📡 Estado de conexión
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                color: _isConnected ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isConnecting 
                    ? 'Conectando...' 
                    : _isConnected 
                        ? 'Conectado al servidor' 
                        : 'Sin conexión',
                style: TextStyle(
                  color: _isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerConfig() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 Configuración del Jugador',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 📝 Nombre del jugador
          TextField(
            controller: _playerNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre del jugador',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white30),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 🎨 Selector de color
          const Text(
            'Color del jugador:',
            style: TextStyle(color: Colors.white70),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: _playerColors.asMap().entries.map((entry) {
              final index = entry.key;
              final color = entry.value;
              final colorName = _colorNames[index];
              final isSelected = _selectedColor == colorName;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorName),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['🏠 Crear Sala', '🚪 Unirse', '📋 Públicas'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _currentTab == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildCreateRoomTab();
      case 1:
        return _buildJoinRoomTab();
      case 2:
        return _buildPublicRoomsTab();
      default:
        return Container();
    }
  }

  Widget _buildCreateRoomTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_rounded,
            size: 80,
            color: Colors.white70,
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Crear Nueva Sala',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Serás el anfitrión de la sala.\nOtros jugadores podrán unirse con el código.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: _isConnected ? _createRoom : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              '🏠 CREAR SALA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRoomTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.login_rounded,
            size: 80,
            color: Colors.white70,
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Unirse a Sala',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Ingresa el código de sala que te\ncompartió el anfitrión.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          
          const SizedBox(height: 32),
          
          TextField(
            controller: _roomCodeController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Código de sala',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white30),
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _canJoinRoom() ? _joinRoom : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              '🚪 UNIRSE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicRoomsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '📋 Salas Públicas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.construction,
                    size: 60,
                    color: Colors.white70,
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    'Próximamente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    'Las salas públicas estarán\ndisponibles en una futura versión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        label: const Text(
          'Volver al Menú',
          style: TextStyle(color: Colors.white),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  // 🏠 CREAR SALA
  Future<void> _createRoom() async {
    if (_playerNameController.text.trim().isEmpty) {
      _showErrorDialog('Error', 'Por favor ingresa tu nombre.');
      return;
    }

    try {
      // 🎯 Generar código de sala único
      final roomCode = 'SALA${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      // 🎮 Navegar a la sala de espera
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineWaitingRoom(
            roomCode: roomCode,
            playerName: _playerNameController.text.trim(),
            playerColor: _playerColors[_colorNames.indexOf(_selectedColor)],
            isHost: true,
          ),
        ),
      );
      
    } catch (e) {
      _showErrorDialog('Error', 'Error inesperado: $e');
    }
  }

  // ✅ VERIFICAR SI SE PUEDE UNIR A SALA
  bool _canJoinRoom() {
    final hasName = _playerNameController.text.trim().isNotEmpty;
    final hasCode = _roomCodeController.text.trim().isNotEmpty;
    final isConnected = _isConnected;
    
    print('🔍 DEBUG _canJoinRoom: hasName=$hasName, hasCode=$hasCode, isConnected=$isConnected');
    
    return hasName && hasCode && isConnected;
  }

  // 🚪 UNIRSE A SALA
  Future<void> _joinRoom() async {
    print('🚀 DEBUG: _joinRoom iniciado');
    
    if (_playerNameController.text.trim().isEmpty) {
      print('❌ ERROR: Nombre vacío');
      _showErrorDialog('Error', 'Por favor ingresa tu nombre.');
      return;
    }

    if (_roomCodeController.text.trim().isEmpty) {
      print('❌ ERROR: Código vacío');
      _showErrorDialog('Error', 'Por favor ingresa el código de sala.');
      return;
    }
    
    print('✅ DEBUG: Validaciones pasadas, navegando a sala de espera');

    try {
      // � Navegar a la sala de espera como invitado
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineWaitingRoom(
            roomCode: _roomCodeController.text.trim().toUpperCase(),
            playerName: _playerNameController.text.trim(),
            playerColor: _playerColors[_colorNames.indexOf(_selectedColor)],
            isHost: false,
          ),
        ),
      );
      
    } catch (e) {
      _showErrorDialog('Error', 'Error inesperado: $e');
    }
  }

  // 📄 DIÁLOGOS
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

}