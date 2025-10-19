import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../models/game_settings.dart';

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
    final currentUser = HiveService.getCurrentUser();
    if (currentUser != null && _nicknameController.text.isNotEmpty) {
      currentUser.name = _nicknameController.text;
      await HiveService.saveCurrentUser(currentUser);
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