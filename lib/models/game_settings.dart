import 'package:hive/hive.dart';

part 'game_settings.g.dart';

@HiveType(typeId: 1)
class GameSettings extends HiveObject {
  @HiveField(0)
  double musicVolume;

  @HiveField(1)
  double effectsVolume;

  @HiveField(2)
  double notificationsVolume;

  @HiveField(3)
  bool soundEnabled;

  @HiveField(4)
  bool musicEnabled;

  @HiveField(5)
  bool notificationsEnabled;

  @HiveField(6)
  bool vibrationEnabled;

  @HiveField(7)
  String language;

  @HiveField(8)
  String theme;

  GameSettings({
    this.musicVolume = 0.7,
    this.effectsVolume = 0.8,
    this.notificationsVolume = 0.6,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.notificationsEnabled = true,
    this.vibrationEnabled = true,
    this.language = 'es',
    this.theme = 'default',
  });

  // Métodos para actualizar configuraciones
  void updateMusicVolume(double volume) {
    musicVolume = volume;
    save();
  }

  void updateEffectsVolume(double volume) {
    effectsVolume = volume;
    save();
  }

  void updateNotificationsVolume(double volume) {
    notificationsVolume = volume;
    save();
  }

  void toggleSound() {
    soundEnabled = !soundEnabled;
    save();
  }

  void toggleMusic() {
    musicEnabled = !musicEnabled;
    save();
  }

  void toggleNotifications() {
    notificationsEnabled = !notificationsEnabled;
    save();
  }

  void toggleVibration() {
    vibrationEnabled = !vibrationEnabled;
    save();
  }

  void updateLanguage(String newLanguage) {
    language = newLanguage;
    save();
  }

  void updateTheme(String newTheme) {
    theme = newTheme;
    save();
  }

  @override
  String toString() {
    return 'GameSettings(music: $musicVolume, effects: $effectsVolume, sound: $soundEnabled)';
  }
}