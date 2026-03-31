import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weekly_schedule_config.dart';
import '../providers/study_plan_provider.dart';

class WeeklyScheduleGeneratorScreen extends StatefulWidget {
  const WeeklyScheduleGeneratorScreen({super.key});

  @override
  State<WeeklyScheduleGeneratorScreen> createState() =>
      _WeeklyScheduleGeneratorScreenState();
}

class _WeeklyScheduleGeneratorScreenState
    extends State<WeeklyScheduleGeneratorScreen> {
  late WeeklyScheduleConfig _config;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _config = WeeklyScheduleConfig.defaultConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Haftalık Ders Planı Oluştur'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Haftanın günleri seçimi
            _buildWeekDaysSection(),
            const SizedBox(height: 24),

            // Günlük ders sayısı
            _buildLessonsPerDaySection(),
            const SizedBox(height: 24),

            // Çalışılacak dersleri seçme
            _buildSubjectsSection(),
            const SizedBox(height: 24),

            // Başlangıç saati
            _buildStartTimeSection(),
            const SizedBox(height: 24),

            // Ders süresi
            _buildLessonDurationSection(),
            const SizedBox(height: 32),

            // Oluştur butonu
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDaysSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📆 Çalışma Günleri Seçin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                return FilterChip(
                  label: Text(weekDays[index]),
                  selected: _config.activeDays[index],
                  onSelected: (selected) {
                    setState(() {
                      final newActiveDays = List<bool>.from(_config.activeDays);
                      newActiveDays[index] = selected;
                      _config = _config.copyWith(activeDays: newActiveDays);
                    });
                  },
                  selectedColor: Colors.blue.shade300,
                  backgroundColor: Colors.grey.shade200,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsPerDaySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📚 Her Gün Ders Sayısı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _config.lessonsPerDay > 1
                      ? () {
                          setState(() {
                            _config = _config.copyWith(
                              lessonsPerDay: _config.lessonsPerDay - 1,
                            );
                          });
                        }
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_config.lessonsPerDay} dersi',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _config.lessonsPerDay < 6
                      ? () {
                          setState(() {
                            _config = _config.copyWith(
                              lessonsPerDay: _config.lessonsPerDay + 1,
                            );
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎓 Çalışılacak Dersleri Seçin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(turkishMiddleSchoolSubjects.length, (index) {
                final subject = turkishMiddleSchoolSubjects[index];
                final isSelected = _config.selectedSubjects.contains(subject);
                return FilterChip(
                  label: Text(subject),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      final newSubjects = List<String>.from(_config.selectedSubjects);
                      if (selected) {
                        newSubjects.add(subject);
                      } else {
                        newSubjects.remove(subject);
                      }
                      _config = _config.copyWith(selectedSubjects: newSubjects);
                    });
                  },
                  selectedColor: Colors.green.shade300,
                  backgroundColor: Colors.grey.shade200,
                );
              }),
            ),
            if (_config.selectedSubjects.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '⚠️ En az 1 ders seçiniz',
                  style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartTimeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⏰ Başlangıç Saati',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _config.startTime,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  '06:00',
                  '07:00',
                  '08:00',
                  '09:00',
                  '10:00',
                  '14:00',
                  '15:00',
                  '16:00',
                  '17:00',
                  '18:00',
                ]
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _config = _config.copyWith(startTime: value);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonDurationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⏱️ Her Ders Süresi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: const [45, 60, 75, 90, 120]
                  .map((duration) => ChoiceChip(
                        label: Text('${duration}dk'),
                        selected: _config.lessonDurationMinutes == duration,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _config = _config.copyWith(
                                lessonDurationMinutes: duration,
                              );
                            });
                          }
                        },
                        selectedColor: Colors.orange.shade300,
                        backgroundColor: Colors.grey.shade200,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _config.selectedSubjects.isEmpty || _isGenerating
            ? null
            : _generateWeeklySchedule,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(
          _isGenerating ? 'Oluşturuluyor...' : '✨ Haftalık Planı Oluştur',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _generateWeeklySchedule() async {
    if (_config.selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir ders seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final studyPlanProvider =
          Provider.of<StudyPlanProvider>(context, listen: false);

      // Mevcut haftalık planı temizle
      await studyPlanProvider.clearWeeklySchedule(DateTime.now());

      // Yeni haftalık planı oluştur
      await studyPlanProvider.generateWeeklySchedule(_config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Haftalık plan başarıyla oluşturuldu! (${_config.selectedSubjects.length} ders, ${_config.activeDays.where((d) => d).length} gün)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Geri dön
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}
