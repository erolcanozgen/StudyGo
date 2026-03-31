class Homework {
  final int? id;
  final String subject;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final int priority; // 1: Düşük, 2: Orta, 3: Yüksek

  Homework({
    this.id,
    required this.subject,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 2,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority,
    };
  }

  Homework copyWith({
    int? id,
    String? subject,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    int? priority,
  }) {
    return Homework(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }

  factory Homework.fromMap(Map<String, dynamic> map) {
    return Homework(
      id: map['id'],
      subject: map['subject'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      priority: map['priority'],
    );
  }
}