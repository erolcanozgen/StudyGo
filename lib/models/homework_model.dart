class Homework {
  final int? id;
  final String subject;
  final String description;
  final DateTime dueDate;
  final String priority; // 'Düşük', 'Orta', 'Yüksek'
  final bool isCompleted;

  Homework({
    this.id,
    required this.subject,
    required this.description,
    required this.dueDate,
    this.priority = 'Orta',
    this.isCompleted = false,
  });

  Homework copyWith({
    int? id,
    String? subject,
    String? description,
    DateTime? dueDate,
    String? priority,
    bool? isCompleted,
  }) {
    return Homework(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Homework.fromMap(Map<String, dynamic> map) {
    return Homework(
      id: map['id'],
      subject: map['subject'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      priority: map['priority'] ?? 'Orta',
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
