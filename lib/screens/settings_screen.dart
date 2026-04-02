import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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