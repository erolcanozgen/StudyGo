import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/study_plan.dart';
import '../models/weekly_schedule_config.dart';
import '../services/database_helper.dart';

class StudyPlanProvider with ChangeNotifier {
  List<StudyPlan> _studyPlans = [];
  bool _isLoading = false;
  bool _isWeb = false;

  List<StudyPlan> get studyPlans => _studyPlans;
  bool get isLoading => _isLoading;

  bool _isDesktopOrMobileSupported() {
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadStudyPlans() async {
    _isWeb = !_isDesktopOrMobileSupported();
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isWeb) {
        try {
          _studyPlans = await DatabaseHelper.instance.getStudyPlans();
        } catch (dbError) {
          print('Database error on mobile: $dbError');
          _studyPlans = [];
        }
      } else {
        // Web: use empty list instead of database
        _studyPlans = [];
      }
    } catch (e) {
      print('Error loading study plans: $e');
      _studyPlans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudyPlansForDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isWeb) {
        _studyPlans = await DatabaseHelper.instance.getStudyPlansForDate(date);
      } else {
        _studyPlans = [];
      }
    } catch (e) {
      print('Error loading study plans for date: $e');
      _studyPlans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStudyPlan(StudyPlan plan) async {
    try {
      _isWeb = !_isDesktopOrMobileSupported();
      
      if (!_isWeb) {
        try {
          final id = await DatabaseHelper.instance.insertStudyPlan(plan);
          final newPlan = StudyPlan(
            id: id,
            subject: plan.subject,
            description: plan.description,
            date: plan.date,
            startTime: plan.startTime,
            endTime: plan.endTime,
            isCompleted: plan.isCompleted,
          );
          _studyPlans.add(newPlan);
          print('✓ Study plan saved to database with ID: $id');
        } catch (dbError) {
          print('✗ Database error adding plan: $dbError');
          throw dbError;
        }
      } else {
        // Web: add plan to memory only
        final newPlan = StudyPlan(
          id: _studyPlans.length + 1,
          subject: plan.subject,
          description: plan.description,
          date: plan.date,
          startTime: plan.startTime,
          endTime: plan.endTime,
          isCompleted: plan.isCompleted,
        );
        _studyPlans.add(newPlan);
        print('✓ Study plan added to memory (web mode)');
      }
      notifyListeners();
    } catch (e) {
      print('✗ Error adding study plan: $e');
      rethrow;
    }
  }

  Future<void> updateStudyPlan(StudyPlan plan) async {
    try {
      _isWeb = !_isDesktopOrMobileSupported();
      
      if (!_isWeb) {
        try {
          await DatabaseHelper.instance.updateStudyPlan(plan);
          print('✓ Study plan updated in database: ${plan.id}');
        } catch (dbError) {
          print('✗ Database error updating plan: $dbError');
        }
      }
      final index = _studyPlans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _studyPlans[index] = plan;
        notifyListeners();
      }
    } catch (e) {
      print('✗ Error updating study plan: $e');
    }
  }

  Future<void> deleteStudyPlan(int id) async {
    try {
      _isWeb = !_isDesktopOrMobileSupported();
      
      if (!_isWeb) {
        try {
          await DatabaseHelper.instance.deleteStudyPlan(id);
          print('✓ Study plan deleted from database: $id');
        } catch (dbError) {
          print('✗ Database error deleting plan: $dbError');
        }
      }
      _studyPlans.removeWhere((plan) => plan.id == id);
      notifyListeners();
    } catch (e) {
      print('✗ Error deleting study plan: $e');
    }
  }

  Future<void> togglePlanCompletion(int id) async {
    final plan = _studyPlans.firstWhere((p) => p.id == id);
    final updatedPlan = StudyPlan(
      id: plan.id,
      subject: plan.subject,
      description: plan.description,
      date: plan.date,
      startTime: plan.startTime,
      endTime: plan.endTime,
      isCompleted: !plan.isCompleted,
    );

    await updateStudyPlan(updatedPlan);
  }

  // Otomatik haftalık ders planı oluşturucu
  Future<void> generateWeeklySchedule(
    WeeklyScheduleConfig config, {
    DateTime? startDate,
  }) async {
    try {
      startDate ??= DateTime.now();
      
      // Haftanın başlangıcını (Pazartesi) bul
      DateTime weekStartDate = startDate;
      while (weekStartDate.weekday != DateTime.monday) {
        weekStartDate = weekStartDate.subtract(const Duration(days: 1));
      }

      // Dersleri karıştır (her gün farklı sıraya gelsin)
      final List<String> subjectsShuffled = List.from(config.selectedSubjects);
      subjectsShuffled.shuffle();

      // Her gün için ders planları oluştur
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        // Bu gün aktif mi kontrol et
        if (!config.activeDays[dayIndex]) {
          continue;
        }

        final currentDate = weekStartDate.add(Duration(days: dayIndex));
        
        // Bu gün için ders sayısı kadar ders ekle
        for (int lessonIndex = 0; lessonIndex < config.lessonsPerDay; lessonIndex++) {
          // Dersi seç (sırayla döngü yap)
          final subjectIndex = (dayIndex * config.lessonsPerDay + lessonIndex) % config.selectedSubjects.length;
          final selectedSubject = config.selectedSubjects[subjectIndex];

          // Saat ve dakikayı parse et
          final startTimeParts = config.startTime.split(':');
          int hour = int.parse(startTimeParts[0]);
          int minute = int.parse(startTimeParts[1]);

          // Her ders için başlangıç saati ekle
          hour += (lessonIndex * config.lessonDurationMinutes) ~/ 60;
          minute += (lessonIndex * config.lessonDurationMinutes) % 60;

          // Dakika 60'ı geçerse düzelt
          if (minute >= 60) {
            hour++;
            minute -= 60;
          }

          // Saat 24'ü geçerse düzelt
          if (hour >= 24) {
            hour = hour % 24;
          }

          final startTimeOfDay = TimeOfDay(hour: hour, minute: minute);

          // Bitiş saatini hesapla
          final endDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          ).add(Duration(minutes: config.lessonDurationMinutes));

          final endTimeOfDay = TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);

          final plan = StudyPlan(
            subject: selectedSubject,
            description: '${weekDays[dayIndex]} - Haftalık ders planı',
            date: currentDate,
            startTime: startTimeOfDay,
            endTime: endTimeOfDay,
            isCompleted: false,
          );

          await addStudyPlan(plan);
        }
      }
    } catch (e) {
      print('Error generating weekly schedule: $e');
    }
  }

  // Haftalık planın tüm gün verilerini temizle
  Future<void> clearWeeklySchedule(DateTime date) async {
    try {
      // Haftanın başını bul
      DateTime weekStart = date;
      while (weekStart.weekday != DateTime.monday) {
        weekStart = weekStart.subtract(const Duration(days: 1));
      }

      // Haftanın sonunu bul
      DateTime weekEnd = weekStart.add(const Duration(days: 6));
      weekEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

      // Bu hafta içindeki tüm planları sil
      for (var plan in List.from(_studyPlans)) {
        if (plan.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            plan.date.isBefore(weekEnd.add(const Duration(days: 1)))) {
          await deleteStudyPlan(plan.id!);
        }
      }
    } catch (e) {
      print('Error clearing weekly schedule: $e');
    }
  }
}