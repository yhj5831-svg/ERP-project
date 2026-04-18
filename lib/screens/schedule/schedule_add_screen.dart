import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/center.dart';

class ScheduleAddScreen extends StatefulWidget {
  final CenterModel center;

  const ScheduleAddScreen({super.key, required this.center});

  @override
  State<ScheduleAddScreen> createState() => _ScheduleAddScreenState();
}

class _ScheduleAddScreenState extends State<ScheduleAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);

  String? selectedStudentId;
  List<Map<String, dynamic>> students = [];

  bool isRecurring = false;
  String recurrenceType = 'weekly';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select('id, name, seat_number')
          .eq('center_id', widget.center.id)
          .eq('status', 'active')
          .order('name');

      setState(() {
        students = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('학생 목록 불러오기 실패: $e');
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate() || selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학생을 선택해주세요'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day,
        startTime.hour, startTime.minute,
      );

      final endDateTime = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day,
        endTime.hour, endTime.minute,
      );

      await Supabase.instance.client.from('schedules').insert({
        'center_id': widget.center.id,
        'student_id': selectedStudentId,
        'title': _titleController.text.trim(),
        'start_time': startDateTime.toIso8601String(),
        'end_time': endDateTime.toIso8601String(),
        'memo': _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        'is_recurring': isRecurring,
        'recurrence_type': isRecurring ? recurrenceType : null,
        'status': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스케줄이 성공적으로 등록되었습니다.'), backgroundColor: Colors.green),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('새 스케줄 등록'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 학생 선택
                DropdownButtonFormField<String>(
                  value: selectedStudentId,
                  decoration: const InputDecoration(
                    labelText: '학생 선택 *',
                    border: OutlineInputBorder(),
                  ),
                  items: students.map<DropdownMenuItem<String>>((student) {
                    return DropdownMenuItem<String>(
                      value: student['id'].toString(),
                      child: Text('${student['name']} (${student['seat_number'] ?? '좌석 미지정'})'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedStudentId = value),
                  validator: (value) => value == null ? '학생을 선택해주세요' : null,
                ),
                const SizedBox(height: 16),

                // 스케줄 제목
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '스케줄 제목 (수업명) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? '제목을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),

                // 날짜 선택
                ListTile(
                  title: const Text('날짜'),
                  subtitle: Text("${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),

                // 시작 시간
                ListTile(
                  title: const Text('시작 시간'),
                  subtitle: Text("${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}"),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: startTime);
                    if (time != null) setState(() => startTime = time);
                  },
                ),

                // 종료 시간
                ListTile(
                  title: const Text('종료 시간'),
                  subtitle: Text("${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}"),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: endTime);
                    if (time != null) setState(() => endTime = time);
                  },
                ),

                const SizedBox(height: 16),

                // 반복 설정
                SwitchListTile(
                  title: const Text('반복 스케줄 설정'),
                  value: isRecurring,
                  onChanged: (val) => setState(() => isRecurring = val),
                ),

                if (isRecurring)
                  DropdownButtonFormField<String>(
                    value: recurrenceType,
                    decoration: const InputDecoration(labelText: '반복 주기'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('매일')),
                      DropdownMenuItem(value: 'weekly', child: Text('매주')),
                    ],
                    onChanged: (val) => setState(() => recurrenceType = val!),
                  ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    labelText: '메모 (선택)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('스케줄 등록하기', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}