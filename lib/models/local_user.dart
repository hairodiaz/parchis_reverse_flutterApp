import 'package:hive/hive.dart';

part 'local_user.g.dart';

@HiveType(typeId: 0)
class LocalUser extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int gamesWon;

  @HiveField(2)
  int gamesPlayed;

  @HiveField(3)
  int currentStreak;

  @HiveField(4)
  int bestStreak;

  @HiveField(5)
  List<String> achievements;

  @HiveField(6)
  bool isGuest;

  @HiveField(7)
  DateTime? lastLoginDate;

  @HiveField(8)
  String? facebookId;

  @HiveField(9)
  String? email;

  LocalUser({
    required this.name,
    this.gamesWon = 0,
    this.gamesPlayed = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.achievements = const [],
    this.isGuest = true,
    this.lastLoginDate,
    this.facebookId,
    this.email,
  });

  // Getters útiles
  double get winRate => gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;
  int get gamesLost => gamesPlayed - gamesWon;
  
  // Métodos para actualizar estadísticas
  void recordWin() {
    gamesWon++;
    gamesPlayed++;
    currentStreak++;
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }
    save(); // Guarda automáticamente en Hive
  }

  void recordLoss() {
    gamesPlayed++;
    currentStreak = 0;
    save();
  }

  void addAchievement(String achievement) {
    if (!achievements.contains(achievement)) {
      achievements.add(achievement);
      save();
    }
  }

  void updateLoginDate() {
    lastLoginDate = DateTime.now();
    save();
  }

  @override
  String toString() {
    return 'LocalUser(name: $name, wins: $gamesWon, games: $gamesPlayed, streak: $currentStreak)';
  }
}