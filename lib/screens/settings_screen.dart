import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/auth_service.dart';
import '../models/game_settings.dart';
import 'instructions_screen.dart';

/// ⚙️ PANTALLA DE CONFIGURACIONES
/// 
/// Funcionalidades:
/// - 🔊 Control de volumen (música, efectos, notificaciones)
/// - 👤 Configuración de nickname
/// - 🎨 Selección de tema
/// - 🌍 Idioma
/// - 📳 Vibración
/// - 💾 Guardado automático en Hive
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _settings;
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    // 📂 Cargar configuraciones desde Hive
    _settings = HiveService.getSettings();
    _nicknameController = TextEditingController();
    
    // 👤 Cargar nickname actual del usuario
    final currentUser = HiveService.getCurrentUser();
    _nicknameController.text = currentUser?.name ?? 'Jugador';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 💾 Guardar configuraciones
  Future<void> _saveSettings() async {
    await HiveService.saveSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuraciones guardadas'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 👤 Guardar nickname
  Future<void> _saveNickname() async {
    if (_nicknameController.text.isNotEmpty) {
      await AuthService().updateNickname(_nicknameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nickname guardado'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuraciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Guardar configuraciones',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 👤 SECCIÓN PERFIL
            _buildSection(
              icon: Icons.person,
              title: 'Perfil',
              children: [
                _buildNicknameField(),
                const SizedBox(height: 16),
                _buildAccountStatus(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 🔊 SECCIÓN AUDIO
            _buildSection(
              icon: Icons.volume_up,
              title: 'Audio',
              children: [
                _buildVolumeSlider(
                  'Música',
                  Icons.music_note,
                  _settings.musicVolume,
                  _settings.musicEnabled,
                  (value) => setState(() => _settings.updateMusicVolume(value)),
                  (enabled) => setState(() => _settings.toggleMusic()),
                ),
                _buildVolumeSlider(
                  'Efectos de sonido',
                  Icons.volume_up,
                  _settings.effectsVolume,
                  _settings.soundEnabled,
                  (value) => setState(() => _settings.updateEffectsVolume(value)),
                  (enabled) => setState(() => _settings.toggleSound()),
                ),
                _buildVolumeSlider(
                  'Notificaciones',
                  Icons.notifications,
                  _settings.notificationsVolume,
                  _settings.notificationsEnabled,
                  (value) => setState(() => _settings.updateNotificationsVolume(value)),
                  (enabled) => setState(() => _settings.toggleNotifications()),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 🎮 SECCIÓN JUEGO
            _buildSection(
              icon: Icons.games,
              title: 'Juego',
              children: [
                _buildSwitchTile(
                  'Vibración',
                  Icons.vibration,
                  _settings.vibrationEnabled,
                  (value) => setState(() => _settings.toggleVibration()),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 📚 SECCIÓN TUTORIALES Y AYUDA
            _buildSection(
              icon: Icons.help_outline,
              title: 'Tutoriales y Ayuda',
              children: [
                _buildSwitchTile(
                  'Mostrar pantalla de bienvenida',
                  Icons.waving_hand,
                  HiveService.getShowWelcomeScreen(),
                  (value) {
                    setState(() {
                      HiveService.setShowWelcomeScreen(value);
                    });
                  },
                ),
                _buildSwitchTile(
                  'Mostrar botón de ayuda en juego',
                  Icons.help_outline,
                  HiveService.getShowGameTips(),
                  (value) {
                    setState(() {
                      HiveService.setShowGameTips(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildTutorialButtons(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 🌍 SECCIÓN GENERAL
            _buildSection(
              icon: Icons.settings,
              title: 'General',
              children: [
                _buildLanguageSelector(),
                _buildThemeSelector(),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 📊 INFORMACIÓN DEBUG
            _buildDebugInfo(),
          ],
        ),
      ),
    );
  }

  /// 📦 Construir sección
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// 👤 Campo de nickname
  Widget _buildNicknameField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: 'Nickname',
              hintText: 'Ingresa tu nombre',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            maxLength: 20,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveNickname,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  /// 🔊 Slider de volumen
  Widget _buildVolumeSlider(
    String title,
    IconData icon,
    double value,
    bool enabled,
    ValueChanged<double> onVolumeChanged,
    ValueChanged<bool> onEnabledChanged,
  ) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(title),
          secondary: Icon(icon),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: Slider(
                    value: value,
                    onChanged: onVolumeChanged,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(value * 100).round()}%',
                  ),
                ),
                const Icon(Icons.volume_up),
              ],
            ),
          ),
        const Divider(),
      ],
    );
  }

  /// 🔘 Switch tile
  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }

  /// 🌍 Selector de idioma
  Widget _buildLanguageSelector() {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Idioma'),
      subtitle: Text(_settings.language == 'es' ? 'Español' : 'English'),
      trailing: DropdownButton<String>(
        value: _settings.language,
        items: const [
          DropdownMenuItem(value: 'es', child: Text('Español')),
          DropdownMenuItem(value: 'en', child: Text('English')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _settings.updateLanguage(value));
          }
        },
      ),
    );
  }

  /// 🎨 Selector de tema
  Widget _buildThemeSelector() {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Tema'),
      subtitle: Text(_settings.theme == 'default' ? 'Por defecto' : 'Oscuro'),
      trailing: DropdownButton<String>(
        value: _settings.theme,
        items: const [
          DropdownMenuItem(value: 'default', child: Text('Por defecto')),
          DropdownMenuItem(value: 'dark', child: Text('Oscuro')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _settings.updateTheme(value));
          }
        },
      ),
    );
  }

  /// � Estado de la cuenta
  Widget _buildAccountStatus() {
    final authService = AuthService();
    final isGuest = authService.isGuest;
    final isLoggedIn = authService.isLoggedIn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLoggedIn ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLoggedIn ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLoggedIn ? Icons.verified_user : Icons.person_outline,
                color: isLoggedIn ? Colors.green.shade600 : Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isLoggedIn ? 'Cuenta Registrada' : 'Usuario Invitado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLoggedIn ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedIn 
                ? 'Tu progreso está guardado en la nube y sincronizado automáticamente.'
                : 'Registra tu cuenta para guardar tu progreso en la nube y acceder a rankings globales.',
            style: TextStyle(
              fontSize: 12,
              color: isLoggedIn ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          if (isGuest) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, size: 18),
                    SizedBox(width: 8),
                    Text('Registrar Cuenta'),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Email: ${authService.userEmail ?? "Sin email"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Mostrar diálogo de confirmación
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cerrar Sesión'),
                        content: const Text('¿Estás seguro de que quieres cerrar sesión? Podrás volver a iniciar sesión cuando quieras.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await authService.logout();
                      if (mounted) {
                        setState(() {}); // Refresh UI
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Sesión cerrada. Ahora eres un usuario invitado.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 📚 Botones de tutorial
  Widget _buildTutorialButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón ver instrucciones
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InstructionsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.help_outline),
          label: const Text('Ver Instrucciones'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botón resetear configuraciones
        OutlinedButton.icon(
          onPressed: () => _showResetTutorialDialog(),
          icon: const Icon(Icons.refresh),
          label: const Text('Resetear Tutoriales'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: BorderSide(color: Colors.orange.shade300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔄 Mostrar diálogo para resetear tutoriales
  void _showResetTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 12),
            Text('Resetear Tutoriales'),
          ],
        ),
        content: const Text(
          'Esto restaurará todas las configuraciones de tutorial a sus valores predeterminados:\n\n'
          '• Pantalla de bienvenida: Activada\n'
          '• Botón de ayuda en juego: Activado\n'
          '• Tutorial para nuevos usuarios: Activado\n\n'
          '¿Deseas continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              HiveService.resetTutorialSettings();
              Navigator.pop(context);
              setState(() {}); // Refresh UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Configuraciones de tutorial reseteadas'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }

  /// 📊 Información de debug
  Widget _buildDebugInfo() {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🐛 Debug Info',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Hive inicializado: ${HiveService.isInitialized}'),
            Text('Usuario actual: ${HiveService.getCurrentUser()?.name ?? "Ninguno"}'),
            Text('Configuraciones: ${_settings.toString()}'),
          ],
        ),
      ),
    );
  }
}