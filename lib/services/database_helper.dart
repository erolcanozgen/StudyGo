import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/study_plan.dart';
import '../models/homework.dart';
import '../models/achievement.dart';
import '../models/user_stats.dart';
import '../models/subject.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('studygo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSubjectsTable(db);
      await _insertDefaultSubjects(db);
    }
  }

  Future _createSubjectsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        colorValue INTEGER NOT NULL,
        isBuiltIn INTEGER NOT NULL
      )
    ''');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE study_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE homeworks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        description TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        priority INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        isUnlocked INTEGER NOT NULL,
        unlockedDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        totalPoints INTEGER NOT NULL,
        completedPlans INTEGER NOT NULL,
        completedHomeworks INTEGER NOT NULL,
        currentStreak INTEGER NOT NULL,
        bestStreak INTEGER NOT NULL,
        unlockedAchievements TEXT NOT NULL
      )
    ''');

    // Başlangıç başarıları ekle
    await _insertInitialAchievements(db);
    // Başlangıç istatistikleri ekle
    await _insertInitialStats(db);
    // Dersler tablosu
    await _createSubjectsTable(db);
    await _insertDefaultSubjects(db);
  }

  Future _insertDefaultSubjects(Database db) async {
    final defaultSubjects = [
      Subject(name: 'Matematik', colorValue: 0xFFE53935, isBuiltIn: true),
      Subject(name: 'Türkçe', colorValue: 0xFFFF6F00, isBuiltIn: true),
      Subject(name: 'İngilizce', colorValue: 0xFF1E88E5, isBuiltIn: true),
      Subject(name: 'Fen Bilgisi', colorValue: 0xFF43A047, isBuiltIn: true),
      Subject(name: 'Sosyal Bilgiler', colorValue: 0xFF7B1FA2, isBuiltIn: true),
      Subject(name: 'Din Kültürü', colorValue: 0xFF0097A7, isBuiltIn: true),
      Subject(name: 'Bilişim Teknolojileri', colorValue: 0xFF3F51B5, isBuiltIn: true),
      Subject(name: 'Teknoloji ve Tasarım', colorValue: 0xFF00BCD4, isBuiltIn: true),
      Subject(name: 'Beden Eğitimi', colorValue: 0xFF7CB342, isBuiltIn: true),
      Subject(name: 'Müzik', colorValue: 0xFFEC407A, isBuiltIn: true),
      Subject(name: 'Resim', colorValue: 0xFFFFA000, isBuiltIn: true),
    ];

    for (final subject in defaultSubjects) {
      await db.insert('subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future _insertInitialAchievements(Database db) async {
    final achievements = [
      Achievement(id: 'first_plan', title: 'İlk Plan', description: 'İlk ders planını oluştur', icon: '📅'),
      Achievement(id: 'first_homework', title: 'İlk Ödev', description: 'İlk ödevini tamamla', icon: '📝'),
      Achievement(id: 'week_streak', title: 'Haftalık Seri', description: '7 gün üst üste çalış', icon: '🔥'),
      Achievement(id: 'homework_master', title: 'Ödev Ustası', description: '10 ödev tamamla', icon: '🏆'),
      Achievement(id: 'planner_pro', title: 'Planlama Profesörü', description: '20 ders planı oluştur', icon: '🎓'),
    ];

    for (final achievement in achievements) {
      await db.insert('achievements', achievement.toMap());
    }
  }

  Future _insertInitialStats(Database db) async {
    final stats = UserStats();
    await db.insert('user_stats', stats.toMap()..['id'] = 1);
  }

  // Study Plans
  Future<List<StudyPlan>> getStudyPlans() async {
    final db = await instance.database;
    final result = await db.query('study_plans');
    return result.map((json) => StudyPlan.fromMap(json)).toList();
  }

  Future<List<StudyPlan>> getStudyPlansForDate(DateTime date) async {
    final db = await instance.database;
    final result = await db.query(
      'study_plans',
      where: 'date = ?',
      whereArgs: [date.toIso8601String().split('T')[0]],
    );
    return result.map((json) => StudyPlan.fromMap(json)).toList();
  }

  Future<int> insertStudyPlan(StudyPlan plan) async {
    final db = await instance.database;
    return await db.insert('study_plans', plan.toMap());
  }

  Future<int> updateStudyPlan(StudyPlan plan) async {
    final db = await instance.database;
    return await db.update(
      'study_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deleteStudyPlan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'study_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Homeworks
  Future<List<Homework>> getHomeworks() async {
    final db = await instance.database;
    final result = await db.query('homeworks', orderBy: 'dueDate ASC');
    return result.map((json) => Homework.fromMap(json)).toList();
  }

  Future<List<Homework>> getPendingHomeworks() async {
    final db = await instance.database;
    final result = await db.query(
      'homeworks',
      where: 'isCompleted = ?',
      whereArgs: [0],
      orderBy: 'dueDate ASC',
    );
    return result.map((json) => Homework.fromMap(json)).toList();
  }

  Future<int> insertHomework(Homework homework) async {
    final db = await instance.database;
    return await db.insert('homeworks', homework.toMap());
  }

  Future<int> updateHomework(Homework homework) async {
    final db = await instance.database;
    return await db.update(
      'homeworks',
      homework.toMap(),
      where: 'id = ?',
      whereArgs: [homework.id],
    );
  }

  Future<int> deleteHomework(int id) async {
    final db = await instance.database;
    return await db.delete(
      'homeworks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Achievements
  Future<List<Achievement>> getAchievements() async {
    final db = await instance.database;
    final result = await db.query('achievements');
    return result.map((json) => Achievement.fromMap(json)).toList();
  }

  Future<int> updateAchievement(Achievement achievement) async {
    final db = await instance.database;
    return await db.update(
      'achievements',
      achievement.toMap(),
      where: 'id = ?',
      whereArgs: [achievement.id],
    );
  }

  // User Stats
  Future<UserStats> getUserStats() async {
    final db = await instance.database;
    final result = await db.query('user_stats');
    if (result.isNotEmpty) {
      return UserStats.fromMap(result.first);
    }
    return UserStats();
  }

  Future<int> updateUserStats(UserStats stats) async {
    final db = await instance.database;
    return await db.update(
      'user_stats',
      stats.toMap()..['id'] = 1,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Subjects
  Future<List<Subject>> getSubjects() async {
    final db = await instance.database;
    final result = await db.query('subjects', orderBy: 'isBuiltIn DESC, name ASC');
    return result.map((json) => Subject.fromMap(json)).toList();
  }

  Future<int> insertSubject(Subject subject) async {
    final db = await instance.database;
    return await db.insert('subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> deleteSubject(int id) async {
    final db = await instance.database;
    return await db.delete(
      'subjects',
      where: 'id = ? AND isBuiltIn = 0',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}