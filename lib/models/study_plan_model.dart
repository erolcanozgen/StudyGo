import 'package:flutter/material.dart';

class StudyPlan {
  final int? id;
  final String lesson;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String description;
  final bool isCompleted;

  StudyPlan({
    this.id,
    required this.lesson,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.description = '',
    this.isCompleted = false,
  });

  StudyPlan copyWith({
    int? id,
    String? lesson,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? description,
    bool? isCompleted,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      lesson: lesson ?? this.lesson,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lesson': lesson,
      'date': date.toIso8601String(),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory StudyPlan.fromMap(Map<String, dynamic> map) {
    final startTimeParts = (map['startTime'] as String).split(':');
    final endTimeParts = (map['endTime'] as String).split(':');

    return StudyPlan(
      id: map['id'],
      lesson: map['lesson'],
      date: DateTime.parse(map['date']),
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
