import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InstructionsScreen extends StatefulWidget {
  final bool showAsFirstTime;
  
  const InstructionsScreen({
    super.key, 
    this.showAsFirstTime = false
  });

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a237e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a237e),
        foregroundColor: Colors.white,
        title: Text(
          widget.showAsFirstTime ? '¡Bienvenido al Parchís!' : '¿Cómo Jugar?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.rule),
              text: 'Reglas',
            ),
            Tab(
              icon: Icon(Icons.grid_3x3),
              text: 'Casillas',
            ),
            Tab(
              icon: Icon(Icons.touch_app),
              text: 'Controles',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicRulesTab(),
          _buildSpecialCellsTab(),
          _buildControlsTab(),
        ],
      ),
      bottomNavigationBar: widget.showAsFirstTime ? _buildFirstTimeActions() : null,
    );
  }

  Widget _buildBasicRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🎯 Objetivo del Juego'),
          _buildRuleCard(
            'Ser el primer jugador en mover todas sus fichas alrededor del tablero y llegar a la META.',
            Icons.flag,
            Colors.green,
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('🎲 Reglas Básicas'),
          
          _buildRuleCard(
            '• Lanza el dado tocándolo.\n'
            '• Mueve tus fichas según el número que salga.\n'
            '• Si sacas 6, tienes un turno extra.\n'
            '• Si sacas 3 seis seguidos, pierdes el turno.',
            Icons.casino,
            Colors.blue,
          ),
          
          _buildRuleCard(
            '• Puedes "comerte" fichas de otros jugadores.\n'
            '• La ficha comida regresa a la SALIDA.\n',
            Icons.sports_kabaddi,
            Colors.orange,
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('🏆 Ganar el Juego'),
          _buildRuleCard(
            'El primer jugador que mueva todas sus fichas a la META gana la partida.',
            Icons.emoji_events,
            Colors.amber,
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('⏱️ Sistema de Tiempo'),
          _buildRuleCard(
            '• Tienes 10 segundos para jugar tu turno\n'
            '• Si no juegas 3 veces seguidas, quedas eliminado\n'
            '• El juego continúa con los jugadores restantes',
            Icons.timer,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialCellsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('✨ Casillas Especiales'),
          
          _buildSpecialCellCard(
            '🍀 LANCE DE NUEVO',
            'Te da un turno extra adicional. ¡Se acumula con el dado 6!',
            Colors.green,
            '¡Doble suerte si sacas 6!',
          ),
          
          _buildSpecialCellCard(
            '🏠 VUELVE A LA SALIDA',
            'Tu ficha regresa automáticamente a la casilla de salida.',
            Colors.blue,
            'Como si te hubieran comido.',
          ),
          
          _buildSpecialCellCard(
            '😴 1 TURNO SIN JUGAR',
            'Pierdes tu próximo turno. Anula TODOS los turnos extra que tengas.',
            Colors.red,
            '¡Cancela beneficios del 6!',
          ),
          
          _buildSpecialCellCard(
            '🚀 SUBE AL 63',
            'Tu ficha vuela directamente a la casilla 63.',
            Colors.purple,
            '¡Jetpack activado!',
          ),
          
          _buildSpecialCellCard(
            '⚡ SUBE AL 70',
            'Tu ficha se teletransporta a la casilla 70.',
            Colors.indigo,
            '¡Turbopropulsado!',
          ),
          
          _buildSpecialCellCard(
            '🛝 BAJA AL 24',
            'Tu ficha se desliza hacia abajo hasta la casilla 24.',
            Colors.orange,
            '¡Tobogán gigante!',
          ),
          
          _buildSpecialCellCard(
            '⬇️ BAJA AL 30',
            'Tu ficha baja automáticamente a la casilla 30.',
            Colors.brown,
            '¡Escalera mecánica rota!',
          ),
          
          const SizedBox(height: 20),
          _buildTipCard(
            '💡 Tip Estratégico',
            'Las casillas especiales pueden cambiar completamente el juego. '
            '¡Úsalas a tu favor y ten cuidado con las trampas!',
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🎮 Controles del Juego'),
          
          _buildControlCard(
            '🎲 Lanzar Dado',
            'Toca el dado para lanzarlo.',
            Icons.touch_app,
            Colors.blue,
          ),
          
          _buildControlCard(
            '🔄 Cambiar Jugada',
            'Si el resultado no te conviene, puedes cambiarlo (3 veces por partida).',
            Icons.refresh,
            Colors.orange,
          ),
          
          _buildControlCard(
            '👆 Mover Ficha',
            'Toca tu ficha para moverla automáticamente.',
            Icons.pan_tool,
            Colors.green,
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('🎯 Tips de Jugabilidad'),
          
          _buildTipCard(
            '⚡ Jugadas Rápidas',
            'El juego se mueve automáticamente para mantener un ritmo ágil. '
            '¡Mantente atento a tu turno!',
            Colors.purple,
          ),
          
          _buildTipCard(
            '🤖 Jugadores CPU',
            'Los jugadores automáticos piensan estratégicamente. '
            '¡Observa sus movimientos para aprender!',
            Colors.indigo,
          ),
          
          _buildTipCard(
            '🎵 Audio y Efectos',
            'Los sonidos te ayudan a seguir el juego. '
            'Cada acción tiene su efecto sonoro único.',
            Colors.teal,
          ),
          
          _buildTipCard(
            '📱 Pantalla Activa',
            'La pantalla se mantiene encendida durante el juego '
            'para que no pierdas tu turno.',
            Colors.amber,
          ),
          
          const SizedBox(height: 20),
          _buildSectionTitle('🏆 Estrategias Ganadoras'),
          
          _buildTipCard(
            '🎯 Prioridades',
            '1. Protege tus fichas cerca de la META.\n'
            '2. Cómete a tus oponentes cuando puedas.\n'
            '3. Usa las casillas especiales tácticamente.',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRuleCard(String text, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialCellCard(String title, String description, Color color, String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstTimeActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¡Ya estás listo para jugar!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Ver Más Tarde'),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '¡A Jugar!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}