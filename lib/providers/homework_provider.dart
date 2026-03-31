import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../models/homework.dart';
import '../services/database_helper.dart';

class HomeworkProvider with ChangeNotifier {
  List<Homework> _homeworks = [];
  bool _isLoading = false;
  bool _isWeb = false;

  List<Homework> get homeworks => _homeworks;
  List<Homework> get pendingHomeworks =>
      _homeworks.where((h) => !h.isCompleted).toList();
  bool get isLoading => _isLoading;

  bool _isDesktopOrMobileSupported() {
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadHomeworks() async {
    _isWeb = !_isDesktopOrMobileSupported();
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isWeb) {
        try {
          _homeworks = await DatabaseHelper.instance.getHomeworks();
        } catch (dbError) {
          print('Database error on mobile: $dbError');
          _homeworks = [];
        }
      } else {
        // Web: use empty list instead of database
        _homeworks = [];
      }
    } catch (e) {
      print('Error loading homeworks: $e');
      _homeworks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHomework(Homework homework) async {
    try {
      int id = homework.id ?? 0;
      if (!_isWeb) {
        id = await DatabaseHelper.instance.insertHomework(homework);
      }
      final newHomework = Homework(
        id: id,
        subject: homework.subject,
        description: homework.description,
        dueDate: homework.dueDate,
        isCompleted: homework.isCompleted,
        priority: homework.priority,
      );
      _homeworks.add(newHomework);
      notifyListeners();
    } catch (e) {
      print('Error adding homework: $e');
    }
  }

  Future<void> updateHomework(Homework homework) async {
    try {
      if (!_isWeb) {
        await DatabaseHelper.instance.updateHomework(homework);
      }
      final index = _homeworks.indexWhere((h) => h.id == homework.id);
      if (index != -1) {
        _homeworks[index] = homework;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating homework: $e');
    }
  }

  Future<void> deleteHomework(int id) async {
    try {
      if (!_isWeb) {
        await DatabaseHelper.instance.deleteHomework(id);
      }
      _homeworks.removeWhere((homework) => homework.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting homework: $e');
    }
  }

  Future<void> toggleHomeworkCompletion(int id) async {
    final homework = _homeworks.firstWhere((h) => h.id == id);
    final updatedHomework = Homework(
      id: homework.id,
      subject: homework.subject,
      description: homework.description,
      dueDate: homework.dueDate,
      isCompleted: !homework.isCompleted,
      priority: homework.priority,
    );

    await updateHomework(updatedHomework);
  }
}