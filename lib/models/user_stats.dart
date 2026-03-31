class UserStats {
  final int totalPoints;
  final int completedPlans;
  final int completedHomeworks;
  final int currentStreak;
  final int bestStreak;
  final List<String> unlockedAchievements;

  UserStats({
    this.totalPoints = 0,
    this.completedPlans = 0,
    this.completedHomeworks = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.unlockedAchievements = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPoints': totalPoints,
      'completedPlans': completedPlans,
      'completedHomeworks': completedHomeworks,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'unlockedAchievements': unlockedAchievements.join(','),
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalPoints: map['totalPoints'] ?? 0,
      completedPlans: map['completedPlans'] ?? 0,
      completedHomeworks: map['completedHomeworks'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      unlockedAchievements: (map['unlockedAchievements'] as String?)?.split(',') ?? [],
    );
  }

  UserStats copyWith({
    int? totalPoints,
    int? completedPlans,
    int? completedHomeworks,
    int? currentStreak,
    int? bestStreak,
    List<String>? unlockedAchievements,
  }) {
    return UserStats(
      totalPoints: totalPoints ?? this.totalPoints,
      completedPlans: completedPlans ?? this.completedPlans,
      completedHomeworks: completedHomeworks ?? this.completedHomeworks,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }
}