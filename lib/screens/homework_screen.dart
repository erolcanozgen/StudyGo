import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/homework.dart';
import '../providers/homework_provider.dart';
import '../providers/user_stats_provider.dart';
import '../providers/subject_provider.dart';
import '../services/notification_service.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  @override
  void initState() {
    super.initState();
    // Ödevleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeworkProvider>().loadHomeworks();
      context.read<SubjectProvider>().loadSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Ödev Takibi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<HomeworkProvider>(
        builder: (context, homeworkProvider, child) {
          if (homeworkProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final homeworks = homeworkProvider.homeworks;

          if (homeworks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '📭 Henüz ödev eklenmemiş',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddHomeworkDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('İlk Ödevini Ekle'),
                  ),
                ],
              ),
            );
          }

          // Ödevleri öncelik ve tarihe göre sırala
          final sortedHomeworks = List<Homework>.from(homeworks)
            ..sort((a, b) {
              // Önce tamamlanmamış olanları
              if (a.isCompleted != b.isCompleted) {
                return a.isCompleted ? 1 : -1;
              }
              // Sonra önceliğe göre
              if (a.priority != b.priority) {
                return b.priority.compareTo(a.priority); // Yüksek öncelik önce
              }
              // Sonra tarihe göre
              return a.dueDate.compareTo(b.dueDate);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedHomeworks.length,
            itemBuilder: (context, index) {
              final homework = sortedHomeworks[index];
              return _buildHomeworkCard(homework);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHomeworkDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHomeworkCard(Homework homework) {
    final isOverdue = homework.dueDate.isBefore(DateTime.now()) && !homework.isCompleted;
    final daysLeft = homework.dueDate.difference(DateTime.now()).inDays;

    Color priorityColor;
    String priorityText;
    switch (homework.priority) {
      case 3:
        priorityColor = Colors.red;
        priorityText = 'Yüksek';
        break;
      case 2:
        priorityColor = Colors.orange;
        priorityText = 'Orta';
        break;
      default:
        priorityColor = Colors.green;
        priorityText = 'Düşük';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: homework.isCompleted
          ? Colors.green[50]
          : isOverdue
              ? Colors.red[50]
              : null,
      child: ListTile(
        leading: Checkbox(
          value: homework.isCompleted,
          onChanged: (value) async {
            if (value == true && !homework.isCompleted) {
              // Tamamlandı işaretlendi, puan ekle
              await context.read<UserStatsProvider>().addPoints(20);
              await context.read<UserStatsProvider>().incrementCompletedHomeworks();
            }
            await context.read<HomeworkProvider>().toggleHomeworkCompletion(homework.id!);
          },
          activeColor: Colors.green,
        ),
        title: Text(
          homework.subject,
          style: TextStyle(
            decoration: homework.isCompleted ? TextDecoration.lineThrough : null,
            color: homework.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(homework.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isOverdue ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy', 'tr_TR').format(homework.dueDate),
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priorityText,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (!homework.isCompleted) ...[
              const SizedBox(height: 4),
              Text(
                isOverdue
                    ? '⏰ Süresi geçmiş!'
                    : daysLeft == 0
                        ? '⏰ Bugün teslim!'
                        : daysLeft == 1
                            ? '⏰ Yarın teslim!'
                            : '$daysLeft gün kaldı',
                style: TextStyle(
                  color: isOverdue ? Colors.red : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
              _showEditHomeworkDialog(homework);
            } else if (value == 'delete') {
              _showDeleteConfirmation(homework);
            }
          },
        ),
      ),
    );
  }

  void _showAddHomeworkDialog() {
    _showHomeworkDialog(null);
  }

  void _showEditHomeworkDialog(Homework homework) {
    _showHomeworkDialog(homework);
  }

  void _showHomeworkDialog(Homework? homework) async {
    final subjectProvider = context.read<SubjectProvider>();
    if (subjectProvider.subjectNames.isEmpty) {
      await subjectProvider.loadSubjects();
    }
    final subjectNames = List<String>.from(subjectProvider.subjectNames);
    if (subjectNames.isEmpty) {
      subjectNames.addAll([
        'Matematik', 'Türkçe', 'Fen Bilimleri', 'Sosyal Bilgiler',
        'İngilizce', 'Din Kültürü', 'Müzik', 'Görsel Sanatlar',
        'Beden Eğitimi', 'Teknoloji ve Tasarım', 'Bilişim',
      ]);
    }
    String? selectedSubject = homework?.subject;
    if (selectedSubject != null && !subjectNames.contains(selectedSubject)) {
      subjectNames.add(selectedSubject);
    }
    final descriptionController = TextEditingController(text: homework?.description ?? '');
    DateTime dueDate = homework?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    int priority = homework?.priority ?? 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(homework == null ? 'Yeni Ödev' : 'Ödevi Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Ders',
                  ),
                  items: subjectNames.map((name) => DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedSubject = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Ödev Açıklaması',
                    hintText: 'Sayfa 45-50, alıştırma 1-10, vb.',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Teslim Tarihi: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => dueDate = date);
                        }
                      },
                      child: Text(DateFormat('dd/MM/yyyy', 'tr_TR').format(dueDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Öncelik:'),
                    Row(
                      children: [
                        Radio<int>(
                          value: 1,
                          groupValue: priority,
                          onChanged: (value) => setState(() => priority = value!),
                        ),
                        const Text('Düşük'),
                        Radio<int>(
                          value: 2,
                          groupValue: priority,
                          onChanged: (value) => setState(() => priority = value!),
                        ),
                        const Text('Orta'),
                        Radio<int>(
                          value: 3,
                          groupValue: priority,
                          onChanged: (value) => setState(() => priority = value!),
                        ),
                        const Text('Yüksek'),
                      ],
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
                if (selectedSubject != null && selectedSubject!.isNotEmpty) {
                  final newHomework = Homework(
                    id: homework?.id,
                    subject: selectedSubject!,
                    description: descriptionController.text,
                    dueDate: dueDate,
                    isCompleted: homework?.isCompleted ?? false,
                    priority: priority,
                  );

                  if (homework == null) {
                    await context.read<HomeworkProvider>().addHomework(newHomework);
                    // Bildirim planla
                    await _scheduleHomeworkReminder(newHomework);
                  } else {
                    await context.read<HomeworkProvider>().updateHomework(newHomework);
                  }

                  Navigator.pop(context);
                }
              },
              child: Text(homework == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Homework homework) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödevi Sil'),
        content: Text('${homework.subject} ödevini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<HomeworkProvider>().deleteHomework(homework.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleHomeworkReminder(Homework homework) async {
    try {
      final reminderTime = homework.dueDate.subtract(const Duration(hours: 24));

      if (reminderTime.isAfter(DateTime.now())) {
        await NotificationService().scheduleHomeworkReminder(
          id: homework.id!,
          title: '📝 Ödev Hatırlatma',
          body: '${homework.subject} ödevinin teslim tarihi yaklaşıyor!',
          scheduledTime: reminderTime,
        );
      }
    } catch (e) {
      print('Homework reminder error: $e');
    }
  }
}