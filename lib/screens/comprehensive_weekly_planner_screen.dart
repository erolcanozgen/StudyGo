import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/study_plan.dart';
import '../models/homework.dart';
import '../models/weekly_schedule_config.dart';
import '../providers/study_plan_provider.dart';
import '../providers/homework_provider.dart';
import '../providers/subject_provider.dart';

class ComprehensiveWeeklyPlannerScreen extends StatefulWidget {
  @override
  State<ComprehensiveWeeklyPlannerScreen> createState() =>
      _ComprehensiveWeeklyPlannerScreenState();
}

class _ComprehensiveWeeklyPlannerScreenState
    extends State<ComprehensiveWeeklyPlannerScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late WeeklyScheduleConfig _config;
  bool _isConfigExpanded = false;
  bool _isAddingNewItem = false;
  bool _showWeeklyGrid = false;

  // Konfigürasyon kontrolleri
  late List<bool> _selectedDays;
  late int _dailyLessonsCount;
  late List<String> _selectedSubjects;
  late TimeOfDay _startTime;
  late int _lessonDuration;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _initializeConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SubjectProvider>().loadSubjects();
      await context.read<StudyPlanProvider>().loadStudyPlans();
      await context.read<HomeworkProvider>().loadHomeworks();
    });
  }

  void _initializeConfig() {
    _selectedDays = [
      true,
      true,
      true,
      true,
      true,
      false,
      false
    ]; // Pazartesi-Cuma
    _dailyLessonsCount = 2;
    _selectedSubjects = [
      'Matematik',
      'Türkçe',
      'İngilizce',
      'Fen Bilgisi',
      'Sosyal Bilgiler'
    ];
    _startTime = TimeOfDay(hour: 8, minute: 0);
    _lessonDuration = 90;
  }

  Map<String, Color> get _subjectColors {
    return context.read<SubjectProvider>().subjectColorMap;
  }

  List<StudyPlan> _getPlansForDay(DateTime day) {
    final plans = context.watch<StudyPlanProvider>().studyPlans;
    return plans.where((plan) => isSameDay(plan.date, day)).toList();
  }

  List<Homework> _getHomeworkForDay(DateTime day) {
    final homeworks = context.watch<HomeworkProvider>().homeworks;
    return homeworks
        .where((homework) => isSameDay(homework.dueDate, day))
        .toList();
  }

  void _showAddItemBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddItemBottomSheet(
        selectedDay: _selectedDay,
        onAddPlan: (lesson, startTime, endTime, description) async {
          print('📝 Adding study plan: $lesson');
          await context.read<StudyPlanProvider>().addStudyPlan(
                StudyPlan(
                  subject: lesson,
                  description: description,
                  date: _selectedDay,
                  startTime: startTime,
                  endTime: endTime,
                ),
              );
          print('✓ Study plan added successfully');
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✨ Ders eklendi!')),
            );
            setState(() {});
          }
        },
        onAddHomework: (subject, description, dueDate, priority) async {
          print('📝 Adding homework: $subject');
          int priorityValue = priority == 'Yüksek'
              ? 3
              : priority == 'Orta'
                  ? 2
                  : 1;
          await context.read<HomeworkProvider>().addHomework(
                Homework(
                  subject: subject,
                  description: description,
                  dueDate: dueDate,
                  priority: priorityValue,
                ),
              );
          print('✓ Homework added successfully');
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✨ Ödev eklendi!')),
            );
            setState(() {});
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📅 Haftalık Planlayıcı'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.purple.shade400,
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            tooltip: 'Programı Yazdır',
            onPressed: _exportSchedulePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Konfigürasyon Bölümü
            _buildConfigurationSection(),

            // Takvim
            _buildCalendarSection(),

            // Görünüm değiştirici
            _buildViewToggle(),
            SizedBox(height: 8),

            // Haftalık tablo veya günlük detay
            if (_showWeeklyGrid)
              _buildWeeklyGridView()
            else
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('EEEE, d MMMM y', 'tr_TR').format(_selectedDay)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildDayDetails(),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemBottomSheet,
        backgroundColor: Colors.purple.shade400,
        child: Icon(Icons.add),
        tooltip: 'Ders / Ödev Ekle',
      ),
    );
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime _getWeekStart(DateTime day) =>
      DateTime(day.year, day.month, day.day)
          .subtract(Duration(days: day.weekday - 1));

  Widget _buildViewToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showWeeklyGrid = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showWeeklyGrid
                      ? Colors.purple.shade400
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '📋 Günlük',
                    style: TextStyle(
                      color: !_showWeeklyGrid
                          ? Colors.white
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showWeeklyGrid = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showWeeklyGrid
                      ? Colors.purple.shade400
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '📊 Haftalık Tablo',
                    style: TextStyle(
                      color: _showWeeklyGrid
                          ? Colors.white
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGridView() {
    final weekStart = _getWeekStart(_focusedDay);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final plans = context.watch<StudyPlanProvider>().studyPlans;

    // Haftanın planlarını grupla
    Map<int, List<StudyPlan>> weekPlans = {};
    for (int i = 0; i < 7; i++) {
      weekPlans[i] = plans
          .where((p) => isSameDay(p.date, days[i]))
          .toList()
        ..sort((a, b) => (a.startTime.hour * 60 + a.startTime.minute)
            .compareTo(b.startTime.hour * 60 + b.startTime.minute));
    }

    // Saat aralığını belirle
    int minHour = 8;
    int maxHour = 18;
    for (var dayPlans in weekPlans.values) {
      for (var plan in dayPlans) {
        if (plan.startTime.hour < minHour) minHour = plan.startTime.hour;
        if (plan.endTime.hour >= maxHour) {
          maxHour = plan.endTime.hour + (plan.endTime.minute > 0 ? 1 : 0);
        }
      }
    }
    if (maxHour <= minHour) maxHour = minHour + 1;

    final hours = List.generate(maxHour - minHour, (i) => minHour + i);
    const double timeColWidth = 46;
    const double dayColWidth = 80;
    const double rowHeight = 52;

    return Container(
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: timeColWidth + 7 * dayColWidth,
          child: Column(
            children: [
              // Başlık satırı
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade500, Colors.purple.shade700],
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: timeColWidth,
                      height: 48,
                      child: Center(
                        child: Text('⏰', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    ...List.generate(7, (i) {
                      final isToday = isSameDay(days[i], DateTime.now());
                      return Container(
                        width: dayColWidth,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.white.withOpacity(0.15)
                              : null,
                          border: Border(
                            left: BorderSide(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayLabels[i],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              DateFormat('d/M').format(days[i]),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Saat satırları
              ...hours.map((hour) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Saat etiketi
                      Container(
                        width: timeColWidth,
                        height: rowHeight,
                        alignment: Alignment.topCenter,
                        padding: EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Gün sütunları
                      ...List.generate(7, (dayIndex) {
                        final dayPlansList = weekPlans[dayIndex]!;
                        final matchingPlans = dayPlansList.where((p) {
                          final pStart =
                              p.startTime.hour * 60 + p.startTime.minute;
                          final pEnd =
                              p.endTime.hour * 60 + p.endTime.minute;
                          final slotStart = hour * 60;
                          final slotEnd = (hour + 1) * 60;
                          return pStart < slotEnd && pEnd > slotStart;
                        }).toList();

                        if (matchingPlans.isEmpty) {
                          return Container(
                            width: dayColWidth,
                            height: rowHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                            ),
                          );
                        }

                        final plan = matchingPlans.first;
                        final color =
                            _subjectColors[plan.subject] ?? Colors.grey;

                        // Bu plan bu saat diliminde ilk defa mı görünüyor?
                        bool isFirstSlot = true;
                        if (hour > minHour) {
                          final prevMatching = dayPlansList.where((p) {
                            final pS = p.startTime.hour * 60 + p.startTime.minute;
                            final pE = p.endTime.hour * 60 + p.endTime.minute;
                            return pS < hour * 60 && pE > (hour - 1) * 60;
                          }).toList();
                          if (prevMatching.isNotEmpty && prevMatching.first.id == plan.id) {
                            isFirstSlot = false;
                          }
                        }

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = plan.date;
                              _focusedDay = plan.date;
                              _showWeeklyGrid = false;
                            });
                          },
                          child: Container(
                            width: dayColWidth,
                            height: rowHeight,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              border: Border(
                                left: BorderSide(
                                    color: Colors.grey.shade200),
                                top: isFirstSlot
                                    ? BorderSide(
                                        color: color, width: 2)
                                    : BorderSide.none,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: isFirstSlot
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        plan.subject,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        '${_fmtTime(plan.startTime)}-${_fmtTime(plan.endTime)}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.4),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
              // Boş planlar için mesaj
              if (weekPlans.values.every((plans) => plans.isEmpty))
                Container(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '📝 Bu hafta için plan yok\n⚙️ Ayarlardan haftalık plan oluşturabilirsin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportSchedulePdf() async {
    final weekStart = _getWeekStart(_focusedDay);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayLabels = [
      'Pazartesi', 'Sali', 'Carsamba', 'Persembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];
    final plans = context.read<StudyPlanProvider>().studyPlans;

    Map<int, List<StudyPlan>> weekPlans = {};
    for (int i = 0; i < 7; i++) {
      weekPlans[i] = plans
          .where((p) => isSameDay(p.date, days[i]))
          .toList()
        ..sort((a, b) => (a.startTime.hour * 60 + a.startTime.minute)
            .compareTo(b.startTime.hour * 60 + b.startTime.minute));
    }

    // Türkçe karakter destekleyen font yükle
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();
    final weekRange =
        '${DateFormat('d MMMM', 'tr_TR').format(days[0])} - ${DateFormat('d MMMM y', 'tr_TR').format(days[6])}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('StudyGo - Haftalık Ders Programı',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(weekRange,
                      style: pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: pw.FixedColumnWidth(50),
                  for (int i = 1; i <= 7; i++)
                    i: pw.FlexColumnWidth(),
                },
                children: [
                  // Başlık satırı
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#7B1FA2')),
                    children: [
                      pw.Container(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Saat',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9)),
                      ),
                      ...List.generate(
                          7,
                          (i) => pw.Container(
                                padding: pw.EdgeInsets.all(5),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  '${dayLabels[i]}\n${DateFormat('d/M').format(days[i])}',
                                  style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8),
                                  textAlign: pw.TextAlign.center,
                                ),
                              )),
                    ],
                  ),
                  // Saat satırları
                  ...List.generate(13, (hourIdx) {
                    final hour = 8 + hourIdx;
                    return pw.TableRow(
                      decoration: hourIdx % 2 == 0
                          ? pw.BoxDecoration(color: PdfColors.grey50)
                          : null,
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        ...List.generate(7, (dayIdx) {
                          final matching = weekPlans[dayIdx]!.where((p) {
                            final pStart =
                                p.startTime.hour * 60 + p.startTime.minute;
                            final pEnd =
                                p.endTime.hour * 60 + p.endTime.minute;
                            return pStart < (hour + 1) * 60 &&
                                pEnd > hour * 60;
                          }).toList();

                          if (matching.isEmpty) {
                            return pw.Container(
                                padding: pw.EdgeInsets.all(4));
                          }

                          final plan = matching.first;
                          // Önceki saatte aynı plan birincil miydi?
                          bool isFirstSlot = true;
                          if (hour > 8) {
                            final prevMatching = weekPlans[dayIdx]!.where((p) {
                              final pS = p.startTime.hour * 60 + p.startTime.minute;
                              final pE = p.endTime.hour * 60 + p.endTime.minute;
                              return pS < hour * 60 && pE > (hour - 1) * 60;
                            }).toList();
                            if (prevMatching.isNotEmpty && prevMatching.first.id == plan.id) {
                              isFirstSlot = false;
                            }
                          }

                          return pw.Container(
                            padding: pw.EdgeInsets.all(4),
                            color: PdfColor.fromHex('#E1BEE7'),
                            child: isFirstSlot
                                ? pw.Text(
                                    '${plan.subject}\n${_fmtTime(plan.startTime)}-${_fmtTime(plan.endTime)}',
                                    style: pw.TextStyle(fontSize: 7),
                                  )
                                : pw.Center(
                                    child: pw.Text('...',
                                        style: pw.TextStyle(
                                            fontSize: 7,
                                            color: PdfColors.grey))),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildConfigurationSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isConfigExpanded = !_isConfigExpanded;
        });
      },
      child: Container(
        margin: EdgeInsets.all(12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '⚙️ Haftalık Ayarları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  _isConfigExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
            if (_isConfigExpanded) ...[
              SizedBox(height: 16),
              _buildDaySelection(),
              SizedBox(height: 12),
              _buildLessonCountSelector(),
              SizedBox(height: 12),
              _buildSubjectSelector(),
              SizedBox(height: 12),
              _buildTimeAndDurationSelector(),
              SizedBox(height: 12),
              _buildGeneratePlanButton(),
              SizedBox(height: 8),
              _buildResetPlanButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelection() {
    List<String> dayNames = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Çalışma Günleri:',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDays[index] = !_selectedDays[index];
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedDays[index]
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      color: _selectedDays[index]
                          ? Colors.purple.shade700
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLessonCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Günlük Ders Sayısı: $_dailyLessonsCount',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            valueIndicatorColor: Colors.purple.shade700,
          ),
          child: Slider(
            value: _dailyLessonsCount.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            label: _dailyLessonsCount.toString(),
            onChanged: (value) {
              setState(() {
                _dailyLessonsCount = value.toInt();
              });
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSelector() {
    List<String> allSubjects = context.watch<SubjectProvider>().subjectNames;
    if (allSubjects.isEmpty) {
      allSubjects = ['Matematik', 'Türkçe', 'İngilizce', 'Fen Bilgisi', 'Sosyal Bilgiler',
        'Din Kültürü', 'Bilişim Teknolojileri', 'Teknoloji ve Tasarım', 'Beden Eğitimi', 'Müzik', 'Resim'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dersleri Seç: (${_selectedSubjects.length}/${allSubjects.length})',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allSubjects.map((subject) {
            bool isSelected = _selectedSubjects.contains(subject);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSubjects.remove(subject);
                  } else {
                    _selectedSubjects.add(subject);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 0 : 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    color: isSelected ? Colors.purple.shade700 : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeAndDurationSelector() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Başlangıç Saati:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (time != null) {
                    setState(() {
                      _startTime = time;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ders Süresi:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: _lessonDuration,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _lessonDuration = value;
                      });
                    }
                  },
                  dropdownColor: Colors.purple.shade600,
                  underline: SizedBox(),
                  items: [45, 60, 75, 90, 120].map((duration) {
                    return DropdownMenuItem(
                      value: duration,
                      child: Text(
                        '${duration} dk',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratePlanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final provider = context.read<StudyPlanProvider>();
          var now = DateTime.now();
          var weekStart = now.subtract(Duration(days: now.weekday - 1));
          int addedCount = 0;

          try {
            // Haftalık plan oluştur
            for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
              if (_selectedDays[dayOffset]) {
                DateTime planDate = DateTime(
                  weekStart.year,
                  weekStart.month,
                  weekStart.day + dayOffset,
                );

                List<String> daySubjects = List.from(_selectedSubjects);
                daySubjects.shuffle();
                daySubjects = daySubjects.take(_dailyLessonsCount).toList();

                for (int i = 0; i < daySubjects.length; i++) {
                  int startMinute = _startTime.hour * 60 +
                      _startTime.minute +
                      (i * _lessonDuration);
                  int endMinute = startMinute + _lessonDuration;

                  TimeOfDay startTime = TimeOfDay(
                    hour: startMinute ~/ 60,
                    minute: startMinute % 60,
                  );
                  TimeOfDay endTime = TimeOfDay(
                    hour: endMinute ~/ 60,
                    minute: endMinute % 60,
                  );

                  await provider.addStudyPlan(
                    StudyPlan(
                      subject: daySubjects[i],
                      description: 'Haftalık plan - ${daySubjects[i]}',
                      date: planDate,
                      startTime: startTime,
                      endTime: endTime,
                    ),
                  );
                  addedCount++;
                }
              }
            }

            print('✓ Weekly plan generated: $addedCount lessons added');

            if (mounted) {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✨ Haftalık plan oluşturuldu! $addedCount ders eklendi.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            print('✗ Error generating weekly plan: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Plan oluşturulurken hata: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.purple.shade700,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '✨ Haftalık Planı Oluştur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResetPlanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('⚠️ Haftalık Planı Sıfırla'),
              content: Text(
                'Bu haftadaki tüm dersler silinecek.\nBu işlem geri alınamaz. Devam etmek istiyor musunuz?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('İptal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Sıfırla'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            try {
              await context
                  .read<StudyPlanProvider>()
                  .clearWeeklySchedule(DateTime.now());
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ Haftalık plan sıfırlandı'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade400,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '🗑️ Haftalık Planı Sıfırla',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) {
          return _getPlansForDay(day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarFormat: CalendarFormat.week,
        availableCalendarFormats: {
          CalendarFormat.week: 'Hafta',
          CalendarFormat.month: 'Ay',
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: TextStyle(
            color: Colors.purple.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.purple.shade400,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(color: Colors.white),
          todayDecoration: BoxDecoration(
            color: Colors.purple.shade200,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: Colors.red.shade400),
        ),
      ),
    );
  }

  Widget _buildDayDetails() {
    List<StudyPlan> dayPlans = _getPlansForDay(_selectedDay);
    List<Homework> dayHomeworks = _getHomeworkForDay(_selectedDay);

    if (dayPlans.isEmpty && dayHomeworks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '📝 Bu gün için plan yok\n➕ Eklemek için aşağıdaki butona tıkla',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dayPlans.isNotEmpty) ...[
          Text(
            '📚 Dersler (${dayPlans.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Column(
            children: dayPlans.map((plan) {
              Color subjectColor = _subjectColors[plan.subject] ?? Colors.grey;
              return Dismissible(
                key: Key('plan_${plan.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Dersi Sil'),
                      content: Text('${plan.subject} dersini silmek istediğinize emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text('Sil'),
                        ),
                      ],
                    ),
                  ) ?? false;
                },
                onDismissed: (direction) async {
                  if (plan.id != null) {
                    await context.read<StudyPlanProvider>().deleteStudyPlan(plan.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🗑️ ${plan.subject} silindi')),
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    border: Border.all(
                      color: subjectColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.subject,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: subjectColor,
                              ),
                            ),
                            Text(
                              '${plan.startTime.format(context)} - ${plan.endTime.format(context)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Dersi Sil'),
                              content: Text('${plan.subject} dersini silmek istediğinize emin misiniz?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: Text('Sil'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && plan.id != null) {
                            await context.read<StudyPlanProvider>().deleteStudyPlan(plan.id!);
                            if (mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('🗑️ ${plan.subject} silindi')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (dayHomeworks.isNotEmpty) SizedBox(height: 16),
        ],
        if (dayHomeworks.isNotEmpty) ...[
          Text(
            '✏️ Ödevler (${dayHomeworks.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Column(
            children: dayHomeworks.map((hw) {
              Color priorityColor = hw.priority == 3
                  ? Colors.red
                  : hw.priority == 2
                      ? Colors.orange
                      : Colors.green;

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  border: Border.all(
                    color: priorityColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hw.subject,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                          Text(
                            hw.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: hw.isCompleted,
                      onChanged: (value) {
                        context.read<HomeworkProvider>().updateHomework(
                              hw.copyWith(isCompleted: value ?? false),
                            );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class AddItemBottomSheet extends StatefulWidget {
  final DateTime selectedDay;
  final Function(String, TimeOfDay, TimeOfDay, String) onAddPlan;
  final Function(String, String, DateTime, String) onAddHomework;

  const AddItemBottomSheet({
    required this.selectedDay,
    required this.onAddPlan,
    required this.onAddHomework,
  });

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  int _selectedTab = 0; // 0: Ders, 1: Ödev

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade400,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📚 Ders Ekle',
                      style: TextStyle(
                        color: _selectedTab == 0
                            ? Colors.purple.shade700
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✏️ Ödev Ekle',
                      style: TextStyle(
                        color: _selectedTab == 1
                            ? Colors.purple.shade700
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildAddLessonForm()
                : _buildAddHomeworkForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddLessonForm() {
    final subjectNames = context.read<SubjectProvider>().subjectNames;
    String? selectedLesson;
    TextEditingController descriptionController = TextEditingController();
    TimeOfDay startTime = TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 9, minute: 30);

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedLesson,
                decoration: InputDecoration(
                  labelText: 'Ders',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.school),
                ),
                items: subjectNames.map((name) => DropdownMenuItem(
                  value: name,
                  child: Text(name),
                )).toList(),
                onChanged: (value) => setState(() => selectedLesson = value),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setState(() {
                            startTime = time;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Başlangıç: ${startTime.format(context)}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (time != null) {
                          setState(() {
                            endTime = time;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Bitiş: ${endTime.format(context)}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedLesson != null && selectedLesson!.isNotEmpty) {
                      try {
                        await widget.onAddPlan(
                          selectedLesson!,
                          startTime,
                          endTime,
                          descriptionController.text,
                        );
                      } catch (e) {
                        print('✗ Error in add plan: $e');
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⚠️ Ders seçiniz')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade400,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '✨ Ders Ekle',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddHomeworkForm() {
    final subjectNames = context.read<SubjectProvider>().subjectNames;
    String? selectedSubject;
    TextEditingController descriptionController = TextEditingController();
    String selectedPriority = 'Orta';
    DateTime dueDate = DateTime.now().add(Duration(days: 1));

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedSubject,
                decoration: InputDecoration(
                  labelText: 'Ders',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.book),
                ),
                items: subjectNames.map((name) => DropdownMenuItem(
                  value: name,
                  child: Text(name),
                )).toList(),
                onChanged: (value) => setState(() => selectedSubject = value),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Ödev Detayları',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      dueDate = date;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Teslim Tarihi:'),
                      Text(
                        DateFormat('d/M/y', 'tr_TR').format(dueDate),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField(
                value: selectedPriority,
                items: ['Düşük', 'Orta', 'Yüksek'].map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedPriority = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Öncelik',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedSubject != null && selectedSubject!.isNotEmpty &&
                        descriptionController.text.isNotEmpty) {
                      try {
                        await widget.onAddHomework(
                          selectedSubject!,
                          descriptionController.text,
                          dueDate,
                          selectedPriority,
                        );
                      } catch (e) {
                        print('✗ Error in add homework: $e');
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⚠️ Form alanlarını doldurunuz')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade400,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '✨ Ödev Ekle',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
