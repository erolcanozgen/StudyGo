import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../services/database_helper.dart';

class SubjectProvider extends ChangeNotifier {
  List<Subject> _subjects = [];
  bool _isLoading = false;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;

  List<String> get subjectNames => _subjects.map((s) => s.name).toList();

  Map<String, Color> get subjectColorMap {
    final map = <String, Color>{};
    for (final s in _subjects) {
      map[s.name] = Color(s.colorValue);
    }
    return map;
  }

  bool _isDesktopOrMobileSupported() {
    try {
      return Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadSubjects() async {
    if (!_isDesktopOrMobileSupported()) return;
    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await DatabaseHelper.instance.getSubjects();
    } catch (e) {
      print('Error loading subjects: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSubject(String name, int colorValue) async {
    if (!_isDesktopOrMobileSupported()) return;
    try {
      final subject = Subject(name: name, colorValue: colorValue, isBuiltIn: false);
      await DatabaseHelper.instance.insertSubject(subject);
      await loadSubjects();
    } catch (e) {
      print('Error adding subject: $e');
    }
  }

  Future<void> deleteSubject(int id) async {
    if (!_isDesktopOrMobileSupported()) return;
    try {
      await DatabaseHelper.instance.deleteSubject(id);
      await loadSubjects();
    } catch (e) {
      print('Error deleting subject: $e');
    }
  }
}
