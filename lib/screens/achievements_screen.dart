import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_stats_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    // Başarıları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserStatsProvider>().loadUserStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Başarılar'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserStatsProvider>(
        builder: (context, statsProvider, child) {
          if (statsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final achievements = statsProvider.achievements;
          final unlockedAchievements = statsProvider.unlockedAchievements;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF9C4), // Açık sarı
                  Color(0xFFFFF59D), // Daha koyu sarı
                ],
              ),
            ),
            child: Column(
              children: [
                // İstatistik kartı
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '🏆 Rozet',
                        unlockedAchievements.length.toString(),
                        Colors.purple,
                      ),
                      _buildStatItem(
                        '⭐ Puan',
                        statsProvider.userStats.totalPoints.toString(),
                        Colors.amber,
                      ),
                      _buildStatItem(
                        '🔥 En İyi Seri',
                        statsProvider.userStats.bestStreak.toString(),
                        Colors.orange,
                      ),
                    ],
                  ),
                ),

                // Başarılar listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      final isUnlocked = unlockedAchievements.contains(achievement);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isUnlocked ? Colors.white : Colors.grey[100],
                        child: ListTile(
                          leading: Text(
                            achievement.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          title: Text(
                            achievement.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement.description,
                                style: TextStyle(
                                  color: isUnlocked ? Colors.black87 : Colors.grey,
                                ),
                              ),
                              if (isUnlocked && achievement.unlockedDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Kazanıldı: ${achievement.unlockedDate!.day}/${achievement.unlockedDate!.month}/${achievement.unlockedDate!.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: isUnlocked
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 28,
                                )
                              : Icon(
                                  Icons.lock,
                                  color: Colors.grey[400],
                                  size: 28,
                                ),
                        ),
                      );
                    },
                  ),
                ),

                // Motivasyon mesajı
                if (unlockedAchievements.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unlockedAchievements.length >= achievements.length
                          ? '🎉 Tüm başarıları kazandın! Harikasın!'
                          : '💪 Devam et, daha fazla başarı seni bekliyor!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}