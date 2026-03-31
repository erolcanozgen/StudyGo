// Türk Ortaokul Müfredatı Dersleri
const List<String> turkishMiddleSchoolSubjects = [
  'Matematik',
  'Türkçe',
  'İngilizce',
  'Fen Bilgisi',
  'Sosyal Bilgiler',
  'Din Kültürü ve Ahlak Bilgisi',
  'Matematik (Tamamlama)',
  'Beden Eğitimi',
  'Müzik',
  'Resim',
  'Bilişim Teknolojileri',
  'Teknoloji ve Tasarım',
];

// Haftanın günleri
const List<String> weekDays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar'
];

// Çalışma periyodları (saatler)
const List<String> studyPeriods = [
  '08:00 - 09:30',
  '09:30 - 11:00',
  '11:00 - 12:30',
  '14:00 - 15:30',
  '15:30 - 17:00',
  '17:00 - 18:30',
];

class WeeklyScheduleConfig {
  // Haftada hangi günlerde çalışılacağı (Pazartesi 0 - Pazar 6)
  final List<bool> activeDays;
  
  // Her gün kaç farklı ders olacağı
  final int lessonsPerDay;
  
  // Çalışma periyodları (örn: 08:00-09:30)
  final List<String> selectedPeriods;
  
  // Çalışılacak dersler
  final List<String> selectedSubjects;
  
  // Her günün başlangıç saati (varsayılan: 08:00)
  final String startTime;
  
  // Her ders süresi (dakika)
  final int lessonDurationMinutes;

  WeeklyScheduleConfig({
    required this.activeDays,
    this.lessonsPerDay = 2,
    required this.selectedPeriods,
    required this.selectedSubjects,
    this.startTime = '08:00',
    this.lessonDurationMinutes = 90,
  });

  // Fabrika: varsayılan konfigürasyon
  factory WeeklyScheduleConfig.defaultConfig() {
    return WeeklyScheduleConfig(
      activeDays: [true, true, true, true, true, false, false], // Pazartesi-Cuma
      lessonsPerDay: 2,
      selectedPeriods: studyPeriods.sublist(0, 4), // İlk 4 periyot
      selectedSubjects: [
        'Matematik',
        'Türkçe',
        'İngilizce',
        'Fen Bilgisi',
        'Sosyal Bilgiler',
      ],
      startTime: '08:00',
      lessonDurationMinutes: 90,
    );
  }

  // Konfigürasyonun kopyası
  WeeklyScheduleConfig copyWith({
    List<bool>? activeDays,
    int? lessonsPerDay,
    List<String>? selectedPeriods,
    List<String>? selectedSubjects,
    String? startTime,
    int? lessonDurationMinutes,
  }) {
    return WeeklyScheduleConfig(
      activeDays: activeDays ?? this.activeDays,
      lessonsPerDay: lessonsPerDay ?? this.lessonsPerDay,
      selectedPeriods: selectedPeriods ?? this.selectedPeriods,
      selectedSubjects: selectedSubjects ?? this.selectedSubjects,
      startTime: startTime ?? this.startTime,
      lessonDurationMinutes: lessonDurationMinutes ?? this.lessonDurationMinutes,
    );
  }

  // JSON'a çevir (kaydetme için)
  Map<String, dynamic> toJson() {
    return {
      'activeDays': activeDays,
      'lessonsPerDay': lessonsPerDay,
      'selectedPeriods': selectedPeriods,
      'selectedSubjects': selectedSubjects,
      'startTime': startTime,
      'lessonDurationMinutes': lessonDurationMinutes,
    };
  }

  // JSON'dan oluştur
  factory WeeklyScheduleConfig.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleConfig(
      activeDays: List<bool>.from(json['activeDays'] ?? [true, true, true, true, true, false, false]),
      lessonsPerDay: json['lessonsPerDay'] ?? 2,
      selectedPeriods: List<String>.from(json['selectedPeriods'] ?? studyPeriods.sublist(0, 4)),
      selectedSubjects: List<String>.from(json['selectedSubjects'] ?? ['Matematik', 'Türkçe', 'İngilizce']),
      startTime: json['startTime'] ?? '08:00',
      lessonDurationMinutes: json['lessonDurationMinutes'] ?? 90,
    );
  }
}
