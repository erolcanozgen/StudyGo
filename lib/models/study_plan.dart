import 'package:flutter/material.dart';

class StudyPlan {
  final int? id;
  final String subject;
  final String description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isCompleted;

  StudyPlan({
    this.id,
    required this.subject,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory StudyPlan.fromMap(Map<String, dynamic> map) {
    final startTimeParts = map['startTime'].split(':');
    final endTimeParts = map['endTime'].split(':');

    return StudyPlan(
      id: map['id'],
      subject: map['subject'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}