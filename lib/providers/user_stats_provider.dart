import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/user_stats.dart';
import '../models/achievement.dart';
import '../services/database_helper.dart';

class UserStatsProvider with ChangeNotifier {
  UserStats _userStats = UserStats();
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  bool _isWeb = false;

  UserStats get userStats => _userStats;
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();
  bool get isLoading => _isLoading;

  Future<void> loadUserStats() async {
    // Check if running on web
    _isWeb = !_isDesktopOrMobileSupported();
    
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isWeb) {
        _userStats = await DatabaseHelper.instance.getUserStats();
        _achievements = await DatabaseHelper.instance.getAchievements();
      } else {
        // Use default values on web
        _userStats = UserStats();
        _achievements = _getDefaultAchievements();
      }
    } catch (e) {
      print('Error loading user stats: $e');
      _userStats = UserStats();
      _achievements = _getDefaultAchievements();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isDesktopOrMobileSupported() {
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: '1',
        title: 'İlk Plan',
        description: 'İlk ders planını oluşturdun!',
        icon: '📅',
        isUnlocked: false,
      ),
      Achievement(
        id: '2',
        title: 'İlk Ödev',
        description: 'İlk ödevini ekledin!',
        icon: '📝',
        isUnlocked: false,
      ),
      Achievement(
        id: '3',
        title: 'Haftalık Seri',
        description: '7 gün üst üste çalıştın!',
        icon: '🔥',
        isUnlocked: false,
      ),
    ];
  }

  Future<void> addPoints(int points) async {
    _userStats = _userStats.copyWith(
      totalPoints: _userStats.totalPoints + points,
    );
    if (!_isWeb) {
      await DatabaseHelper.instance.updateUserStats(_userStats);
    }
    await checkAchievements();
    notifyListeners();
  }

  Future<void> incrementCompletedPlans() async {
    _userStats = _userStats.copyWith(
      completedPlans: _userStats.completedPlans + 1,
    );
    if (!_isWeb) {
      await DatabaseHelper.instance.updateUserStats(_userStats);
    }
    await checkAchievements();
    notifyListeners();
  }

  Future<void> incrementCompletedHomeworks() async {
    _userStats = _userStats.copyWith(
      completedHomeworks: _userStats.completedHomeworks + 1,
    );
    await DatabaseHelper.instance.updateUserStats(_userStats);
    await checkAchievements();
    notifyListeners();
  }

  Future<void> updateStreak(int newStreak) async {
    _userStats = _userStats.copyWith(
      currentStreak: newStreak,
      bestStreak: newStreak > _userStats.bestStreak ? newStreak : _userStats.bestStreak,
    );
    await DatabaseHelper.instance.updateUserStats(_userStats);
    await checkAchievements();
    notifyListeners();
  }

  Future<void> checkAchievements() async {
    // İlk plan başarısı
    if (_userStats.completedPlans >= 1 && !_isAchievementUnlocked('first_plan')) {
      await unlockAchievement('first_plan');
    }

    // İlk ödev başarısı
    if (_userStats.completedHomeworks >= 1 && !_isAchievementUnlocked('first_homework')) {
      await unlockAchievement('first_homework');
    }

    // Haftalık seri başarısı
    if (_userStats.currentStreak >= 7 && !_isAchievementUnlocked('week_streak')) {
      await unlockAchievement('week_streak');
    }

    // Ödev ustası başarısı
    if (_userStats.completedHomeworks >= 10 && !_isAchievementUnlocked('homework_master')) {
      await unlockAchievement('homework_master');
    }

    // Planlama profesörü başarısı
    if (_userStats.completedPlans >= 20 && !_isAchievementUnlocked('planner_pro')) {
      await unlockAchievement('planner_pro');
    }
  }

  bool _isAchievementUnlocked(String achievementId) {
    return _achievements.any((a) => a.id == achievementId && a.isUnlocked);
  }

  Future<void> unlockAchievement(String achievementId) async {
    final achievementIndex = _achievements.indexWhere((a) => a.id == achievementId);
    if (achievementIndex != -1) {
      final achievement = _achievements[achievementIndex];
      final unlockedAchievement = Achievement(
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        isUnlocked: true,
        unlockedDate: DateTime.now(),
      );

      await DatabaseHelper.instance.updateAchievement(unlockedAchievement);
      _achievements[achievementIndex] = unlockedAchievement;

      // Başarıyı unlocked listesine ekle
      final updatedAchievements = List<String>.from(_userStats.unlockedAchievements)
        ..add(achievementId);
      _userStats = _userStats.copyWith(unlockedAchievements: updatedAchievements);
      await DatabaseHelper.instance.updateUserStats(_userStats);

      notifyListeners();
    }
  }
}