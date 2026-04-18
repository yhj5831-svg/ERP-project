import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/center.dart';

class ScheduleEditScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final CenterModel center;

  const ScheduleEditScreen({
    super.key,
    required this.schedule,
    required this.center,
  });

  @override
  State<ScheduleEditScreen> createState() => _ScheduleEditScreenState();
}

class _ScheduleEditScreenState extends State<ScheduleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();

  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  bool isRecurring = false;
  String recurrenceType = 'weekly';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final start = DateTime.parse(widget.schedule['start_time']);
    final end = DateTime.parse(widget.schedule['end_time']);

    selectedDate = start;
    startTime = TimeOfDay(hour: start.hour, minute: start.minute);
    endTime = TimeOfDay(hour: end.hour, minute: end.minute);

    _titleController.text = widget.schedule['title'] ?? '';
    _memoController.text = widget.schedule['memo'] ?? '';
    isRecurring = widget.schedule['is_recurring'] ?? false;
    recurrenceType = widget.schedule['recurrence_type'] ?? 'weekly';
  }

  Future<void> _updateSchedule() async {
    if (!_formKey.currentState!.validate()) return;

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

      await Supabase.instance.client.from('schedules').update({
        'title': _titleController.text.trim(),
        'start_time': startDateTime.toIso8601String(),
        'end_time': endDateTime.toIso8601String(),
        'memo': _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        'is_recurring': isRecurring,
        'recurrence_type': isRecurring ? recurrenceType : null,
      }).eq('id', widget.schedule['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스케줄이 수정되었습니다.'), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true); // 수정 성공 신호
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스케줄 수정'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '스케줄 제목 *'),
                  validator: (value) => value!.isEmpty ? '제목을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),

                ListTile(
                  title: const Text('날짜'),
                  subtitle: Text("${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일"),
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

                ListTile(
                  title: const Text('시작 시간'),
                  subtitle: Text("${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}"),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: startTime);
                    if (time != null) setState(() => startTime = time);
                  },
                ),

                ListTile(
                  title: const Text('종료 시간'),
                  subtitle: Text("${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}"),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: endTime);
                    if (time != null) setState(() => endTime = time);
                  },
                ),

                SwitchListTile(
                  title: const Text('반복 스케줄'),
                  value: isRecurring,
                  onChanged: (val) => setState(() => isRecurring = val),
                ),

                if (isRecurring)
                  DropdownButtonFormField<String>(
                    value: recurrenceType,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('매일')),
                      DropdownMenuItem(value: 'weekly', child: Text('매주')),
                    ],
                    onChanged: (val) => setState(() => recurrenceType = val!),
                  ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _memoController,
                  decoration: const InputDecoration(labelText: '메모'),
                  maxLines: 3,
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateSchedule,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('스케줄 수정하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}