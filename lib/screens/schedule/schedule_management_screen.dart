import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/center.dart';
import 'schedule_add_screen.dart';
import 'schedule_edit_screen.dart';

class ScheduleManagementScreen extends StatefulWidget {
  final CenterModel center;

  const ScheduleManagementScreen({super.key, required this.center});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;

  final List<int> hours = List.generate(15, (index) => 9 + index); // 9시 ~ 23시

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => isLoading = true);
    try {
      final dateStr = selectedDate.toIso8601String().substring(0, 10);

      final response = await Supabase.instance.client
          .from('schedules')
          .select('*, students(name, seat_number)')
          .eq('center_id', widget.center.id)
          .gte('start_time', '$dateStr 00:00:00')
          .lte('end_time', '$dateStr 23:59:59')
          .order('start_time');

      setState(() {
        schedules = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _getScheduleColor(String title) {
    if (title.contains('영어') || title.contains('단어')) return Colors.purple.shade300;
    if (title.contains('수학')) return Colors.orange.shade300;
    if (title.contains('국어')) return Colors.green.shade300;
    return Colors.blue.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${selectedDate.month}월 ${selectedDate.day}일 스케줄'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2027),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
                _loadSchedules();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 날짜 네비게이션
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)));
                    _loadSchedules();
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  "${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
                    _loadSchedules();
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : schedules.isEmpty
                    ? const Center(child: Text('해당 날짜에 등록된 스케줄이 없습니다.'))
                    : SingleChildScrollView(
                        child: Column(
                          children: hours.map((hour) {
                            final hourSchedules = schedules.where((s) {
                              final start = DateTime.parse(s['start_time']);
                              return start.hour == hour;
                            }).toList();

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      "$hour:00",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: hourSchedules.isEmpty
                                        ? const Divider(height: 40)
                                        : Column(
                                            children: hourSchedules.map((item) {
                                              final student = item['students'] ?? {};
                                              final start = DateTime.parse(item['start_time']);
                                              final end = DateTime.parse(item['end_time']);

                                              return GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ScheduleEditScreen(
                                                        schedule: item,
                                                        center: widget.center,
                                                      ),
                                                    ),
                                                  ).then((result) {
                                                    if (result == true) _loadSchedules();
                                                  });
                                                },
                                                child: Card(
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  color: Colors.white,
                                                  elevation: 2,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(12),
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor: _getScheduleColor(item['title'] ?? ''),
                                                          child: Text(student['name']?.substring(0, 1) ?? '?'),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                item['title'] ?? '수업',
                                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                              ),
                                                              Text(
                                                                '${student['name'] ?? ''} • 좌석 ${student['seat_number'] ?? '-'}',
                                                                style: const TextStyle(color: Colors.grey),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Text(
                                                          "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}~"
                                                          "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleAddScreen(center: widget.center),
            ),
          ).then((_) => _loadSchedules());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}