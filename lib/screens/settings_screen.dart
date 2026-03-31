import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import '../providers/study_plan_provider.dart';
import '../providers/homework_provider.dart';
import '../providers/user_stats_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Ayarlar'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Bildirim ayarları
          const _SettingsSection(
            title: '🔔 Bildirimler',
            children: [
              _NotificationSetting(
                title: 'Çalışma Hatırlatmaları',
                subtitle: 'Ders çalışma zamanından 15 dakika önce hatırlat',
              ),
              _NotificationSetting(
                title: 'Ödev Hatırlatmaları',
                subtitle: 'Ödev teslim tarihinden 1 gün önce hatırlat',
              ),
            ],
          ),

          // Veri yönetimi
          _SettingsSection(
            title: '💾 Veri Yönetimi',
            children: [
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Ders Programını Yazdır'),
                subtitle: const Text('Mevcut haftanın ders programını PDF olarak dışa aktar'),
                onTap: () => _exportStudySchedule(context),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Ödev Listesini Yazdır'),
                subtitle: const Text('Tüm ödevleri PDF olarak dışa aktar'),
                onTap: () => _exportHomeworkList(context),
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('İstatistik Raporu'),
                subtitle: const Text('Çalışma istatistiklerini PDF olarak dışa aktar'),
                onTap: () => _exportStatisticsReport(context),
              ),
            ],
          ),

          // Uygulama hakkında
          const _SettingsSection(
            title: 'ℹ️ Uygulama Hakkında',
            children: [
              ListTile(
                leading: Icon(Icons.info, color: Colors.blue),
                title: Text('Versiyon'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: Text('Geliştirici'),
                subtitle: Text('StudyGo Ekibi'),
              ),
              ListTile(
                leading: Icon(Icons.email, color: Colors.green),
                title: Text('İletişim'),
                subtitle: Text('destek@studygo.com'),
              ),
            ],
          ),

          // Tehlikeli işlemler
          _SettingsSection(
            title: '⚠️ Tehlikeli İşlemler',
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Tüm Verileri Sil'),
                subtitle: const Text('Bu işlem geri alınamaz'),
                onTap: () => _showDeleteAllDataDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportStudySchedule(BuildContext context) async {
    final planProvider = context.read<StudyPlanProvider>();
    await planProvider.loadStudyPlans();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('StudyGo - Ders Programı',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              ...planProvider.studyPlans.map((plan) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(plan.subject,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(plan.description),
                      pw.Text(
                          '${_formatTime(plan.startTime)} - ${_formatTime(plan.endTime)}'),
                      pw.Text(plan.date.toString().split(' ')[0]),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _exportHomeworkList(BuildContext context) async {
    final homeworkProvider = context.read<HomeworkProvider>();
    await homeworkProvider.loadHomeworks();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('StudyGo - Ödev Listesi',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              ...homeworkProvider.homeworks.map((homework) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(homework.subject,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(homework.description),
                      pw.Text('Teslim: ${homework.dueDate.toString().split(' ')[0]}'),
                      pw.Text('Durum: ${homework.isCompleted ? 'Tamamlandı' : 'Bekliyor'}'),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _exportStatisticsReport(BuildContext context) async {
    final statsProvider = context.read<UserStatsProvider>();
    await statsProvider.loadUserStats();

    final pdf = pw.Document();
    final stats = statsProvider.userStats;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('StudyGo - İstatistik Raporu',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Toplam Puan: ${stats.totalPoints}'),
              pw.Text('Tamamlanan Plan: ${stats.completedPlans}'),
              pw.Text('Tamamlanan Ödev: ${stats.completedHomeworks}'),
              pw.Text('Mevcut Seri: ${stats.currentStreak}'),
              pw.Text('En İyi Seri: ${stats.bestStreak}'),
              pw.SizedBox(height: 20),
              pw.Text('Kazanılan Başarılar:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...statsProvider.unlockedAchievements.map((achievement) {
                return pw.Text('• ${achievement.title}');
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _showDeleteAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Tüm Verileri Sil'),
        content: const Text(
            'Bu işlem tüm ders planlarınızı, ödevlerinizi ve istatistiklerinizi kalıcı olarak silecektir. Bu işlem geri alınamaz. Devam etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Burada veri silme işlemi yapılacak
              // Şimdilik sadece snackbar göster
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veri silme özelliği yakında eklenecek')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}

class _NotificationSetting extends StatefulWidget {
  final String title;
  final String subtitle;

  const _NotificationSetting({
    required this.title,
    required this.subtitle,
  });

  @override
  State<_NotificationSetting> createState() => _NotificationSettingState();
}

class _NotificationSettingState extends State<_NotificationSetting> {
  bool _isEnabled = true; // Varsayılan olarak açık

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      value: _isEnabled,
      onChanged: (value) {
        setState(() => _isEnabled = value);
        // Burada bildirim ayarları kaydedilecek
      },
    );
  }
}