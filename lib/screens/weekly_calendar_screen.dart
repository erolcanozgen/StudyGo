import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/study_plan.dart';
import '../providers/study_plan_provider.dart';

class WeeklyCalendarScreen extends StatefulWidget {
  const WeeklyCalendarScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyPlanProvider>().loadStudyPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📅 Haftalık Takvim',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: _buildSelectedDayPlans(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: TableCalendar<StudyPlan>(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue.shade300,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.green.shade500,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(
            color: Colors.red.shade600,
            fontWeight: FontWeight.bold,
          ),
          outsideTextStyle: const TextStyle(
            color: Colors.grey,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: Colors.blue.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Colors.blue.shade700,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Colors.blue.shade700,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
          weekendStyle: TextStyle(
            color: Colors.red.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        eventLoader: (day) {
          final plans = context.read<StudyPlanProvider>().studyPlans;
          return plans
              .where((plan) => isSameDay(plan.date, day))
              .toList();
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox();
            return Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayPlans() {
    return Consumer<StudyPlanProvider>(
      builder: (context, provider, _) {
        final plans = provider.studyPlans
            .where((plan) => isSameDay(plan.date, _selectedDay))
            .toList();

        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu gün için ders planı yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'tr_TR').format(_selectedDay),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.blue.shade200,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE', 'tr_TR').format(_selectedDay),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${plans.length} ders',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return _buildPlanCard(plan, context, provider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlanCard(StudyPlan plan, BuildContext context, StudyPlanProvider provider) {
    final startTime = '${plan.startTime.hour.toString().padLeft(2, '0')}:${plan.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${plan.endTime.hour.toString().padLeft(2, '0')}:${plan.endTime.minute.toString().padLeft(2, '0')}';
    final courseName = _getCourseName(plan.subject);
    final courseColor = _getCourseColor(plan.subject);
    final courseIcon = _getCourseIcon(plan.subject);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [courseColor, courseColor.withOpacity(0.7)],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              courseIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          title: Text(
            courseName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (plan.description.isNotEmpty)
                Text(
                  plan.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🕐 $startTime - $endTime',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          trailing: Checkbox(
            value: plan.isCompleted,
            onChanged: (value) {
              final updatedPlan = StudyPlan(
                id: plan.id,
                subject: plan.subject,
                description: plan.description,
                date: plan.date,
                startTime: plan.startTime,
                endTime: plan.endTime,
                isCompleted: value ?? false,
              );
              provider.updateStudyPlan(updatedPlan);
            },
            activeColor: Colors.white,
            checkColor: courseColor,
            side: BorderSide(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
          ),
          onTap: () {
            _showPlanDetails(context, plan, provider);
          },
        ),
      ),
    );
  }

  void _showPlanDetails(BuildContext context, StudyPlan plan, StudyPlanProvider provider) {
    final startTime = '${plan.startTime.hour.toString().padLeft(2, '0')}:${plan.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${plan.endTime.hour.toString().padLeft(2, '0')}:${plan.endTime.minute.toString().padLeft(2, '0')}';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getCourseIcon(plan.subject),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCourseName(plan.subject),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'tr_TR').format(plan.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              const Text(
                'Zaman',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '🕐 $startTime - $endTime',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (plan.description.isNotEmpty) ...[
                const Text(
                  'Açıklama',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final updatedPlan = StudyPlan(
                        id: plan.id,
                        subject: plan.subject,
                        description: plan.description,
                        date: plan.date,
                        startTime: plan.startTime,
                        endTime: plan.endTime,
                        isCompleted: !plan.isCompleted,
                      );
                      provider.updateStudyPlan(updatedPlan);
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      plan.isCompleted ? Icons.close : Icons.check,
                    ),
                    label: Text(
                      plan.isCompleted ? 'İptal Et' : 'Tamamla',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isCompleted
                          ? Colors.orange.shade500
                          : Colors.green.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCourseName(String subject) {
    final courses = {
      'Matematik': 'Matematik',
      'Türkçe': 'Türkçe',
      'İngilizce': 'İngilizce',
      'Fen Bilgisi': 'Fen Bilgisi',
      'Sosyal Bilgiler': 'Sosyal Bilgiler',
      'Din Kültürü': 'Din Kültürü',
      'Bilişim Teknolojileri': 'BT',
      'Teknoloji ve Tasarım': 'T&T',
      'Beden Eğitimi': 'Beden Eğitimi',
      'Müzik': 'Müzik',
      'Resim': 'Resim',
    };
    return courses[subject] ?? subject;
  }

  Color _getCourseColor(String subject) {
    final colors = {
      'Matematik': Colors.red,
      'Türkçe': Colors.orange,
      'İngilizce': Colors.blue,
      'Fen Bilgisi': Colors.green,
      'Sosyal Bilgiler': Colors.purple,
      'Din Kültürü': Colors.teal,
      'Bilişim Teknolojileri': Colors.indigo,
      'Teknoloji ve Tasarım': Colors.cyan,
      'Beden Eğitimi': Colors.lime,
      'Müzik': Colors.pink,
      'Resim': Colors.amber,
    };
    return colors[subject] ?? Colors.blue;
  }

  String _getCourseIcon(String subject) {
    final icons = {
      'Matematik': '🔢',
      'Türkçe': '📖',
      'İngilizce': '🌍',
      'Fen Bilgisi': '🔬',
      'Sosyal Bilgiler': '🌍',
      'Din Kültürü': '🕌',
      'Bilişim Teknolojileri': '💻',
      'Teknoloji ve Tasarım': '🛠️',
      'Beden Eğitimi': '⚽',
      'Müzik': '🎵',
      'Resim': '🎨',
    };
    return icons[subject] ?? '📚';
  }
}
