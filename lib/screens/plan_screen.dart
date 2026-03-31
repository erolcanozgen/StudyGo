import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/study_plan.dart';
import '../providers/study_plan_provider.dart';
import '../providers/user_stats_provider.dart';
import '../services/notification_service.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Seçili tarihe göre planları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlansForDate(_selectedDate);
    });
  }

  void _loadPlansForDate(DateTime date) {
    context.read<StudyPlanProvider>().loadStudyPlansForDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Ders Planı'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tarih seçici
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                    _loadPlansForDate(_selectedDate);
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _loadPlansForDate(_selectedDate);
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Plan listesi
          Expanded(
            child: Consumer<StudyPlanProvider>(
              builder: (context, planProvider, child) {
                if (planProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final plans = planProvider.studyPlans;

                if (plans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '📭 Bu tarihte plan bulunmuyor',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddPlanDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('İlk Planını Oluştur'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return _buildPlanCard(plan);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlanDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPlanCard(StudyPlan plan) {
    final startTime = '${plan.startTime.hour.toString().padLeft(2, '0')}:${plan.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${plan.endTime.hour.toString().padLeft(2, '0')}:${plan.endTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: plan.isCompleted,
          onChanged: (value) async {
            if (value == true && !plan.isCompleted) {
              // Tamamlandı işaretlendi, puan ekle
              await context.read<UserStatsProvider>().addPoints(10);
              await context.read<UserStatsProvider>().incrementCompletedPlans();
            }
            await context.read<StudyPlanProvider>().togglePlanCompletion(plan.id!);
          },
          activeColor: Colors.green,
        ),
        title: Text(
          plan.subject,
          style: TextStyle(
            decoration: plan.isCompleted ? TextDecoration.lineThrough : null,
            color: plan.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.description),
            Text('$startTime - $endTime'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Düzenle'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Sil'),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditPlanDialog(plan);
            } else if (value == 'delete') {
              _showDeleteConfirmation(plan);
            }
          },
        ),
      ),
    );
  }

  void _showAddPlanDialog() {
    _showPlanDialog(null);
  }

  void _showEditPlanDialog(StudyPlan plan) {
    _showPlanDialog(plan);
  }

  void _showPlanDialog(StudyPlan? plan) {
    final subjectController = TextEditingController(text: plan?.subject ?? '');
    final descriptionController = TextEditingController(text: plan?.description ?? '');
    TimeOfDay startTime = plan?.startTime ?? TimeOfDay.now();
    final nextHour = (TimeOfDay.now().hour + 1) % 24;
    TimeOfDay endTime = plan?.endTime ?? TimeOfDay.now().replacing(hour: nextHour);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(plan == null ? 'Yeni Ders Planı' : 'Ders Planını Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Ders Adı',
                    hintText: 'Matematik, Türkçe, vb.',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Konu, sayfa, vb.',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Başlangıç Saati'),
                          TextButton(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (time != null) {
                                setState(() => startTime = time);
                              }
                            },
                            child: Text(startTime.format(context)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bitiş Saati'),
                          TextButton(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (time != null) {
                                setState(() => endTime = time);
                              }
                            },
                            child: Text(endTime.format(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (subjectController.text.isNotEmpty) {
                  final newPlan = StudyPlan(
                    id: plan?.id,
                    subject: subjectController.text,
                    description: descriptionController.text,
                    date: _selectedDate,
                    startTime: startTime,
                    endTime: endTime,
                    isCompleted: plan?.isCompleted ?? false,
                  );

                  if (plan == null) {
                    await context.read<StudyPlanProvider>().addStudyPlan(newPlan);
                    // Bildirim planla
                    await _scheduleStudyReminder(newPlan);
                  } else {
                    await context.read<StudyPlanProvider>().updateStudyPlan(newPlan);
                  }

                  Navigator.pop(context);
                }
              },
              child: Text(plan == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(StudyPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Planı Sil'),
        content: Text('${plan.subject} ders planını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<StudyPlanProvider>().deleteStudyPlan(plan.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleStudyReminder(StudyPlan plan) async {
    final reminderTime = DateTime(
      plan.date.year,
      plan.date.month,
      plan.date.day,
      plan.startTime.hour,
      plan.startTime.minute,
    ).subtract(const Duration(minutes: 15)); // 15 dakika önce hatırlat

    if (reminderTime.isAfter(DateTime.now())) {
      await NotificationService().scheduleStudyReminder(
        id: plan.id!,
        title: '📚 Çalışma Zamanı!',
        body: '${plan.subject} dersi için çalışma zamanın geldi!',
        scheduledTime: reminderTime,
      );
    }
  }
}