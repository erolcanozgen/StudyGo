class Subject {
  final int? id;
  final String name;
  final int colorValue;
  final bool isBuiltIn;

  Subject({
    this.id,
    required this.name,
    required this.colorValue,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'isBuiltIn': isBuiltIn ? 1 : 0,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int,
      isBuiltIn: (map['isBuiltIn'] as int) == 1,
    );
  }
}
