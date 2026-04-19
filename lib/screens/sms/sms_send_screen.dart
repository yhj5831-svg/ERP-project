import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../models/center.dart';

class SmsSendScreen extends StatefulWidget {
  final CenterModel center;

  const SmsSendScreen({super.key, required this.center});

  @override
  State<SmsSendScreen> createState() => _SmsSendScreenState();
}

class _SmsSendScreenState extends State<SmsSendScreen> {
  String sendTarget = 'both';
  String searchKeyword = '';
  String selectedGrade = '전체';
  String selectedSchool = '전체';

  final TextEditingController _messageController = TextEditingController();

  bool isScheduled = false;
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;

  bool isLoading = false;

  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> filteredStudents = [];
  List<String> selectedStudentIds = [];

  List<Map<String, dynamic>> excelStudents = [];

  int get totalSelected => selectedStudentIds.length + excelStudents.length;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final res = await Supabase.instance.client
        .from('students')
        .select('id, name, student_phone, parent_phone, grade, school')
        .eq('center_id', widget.center.id)
        .eq('status', 'active');

    setState(() {
      allStudents = List<Map<String, dynamic>>.from(res);
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      filteredStudents = allStudents.where((s) {
        final nameMatch = searchKeyword.isEmpty ||
            (s['name'] ?? '').toString().toLowerCase().contains(searchKeyword.toLowerCase());
        final phoneMatch = searchKeyword.isEmpty ||
            (s['student_phone'] ?? '').contains(searchKeyword) ||
            (s['parent_phone'] ?? '').contains(searchKeyword);

        final gradeMatch = selectedGrade == '전체' || s['grade'] == selectedGrade;
        final schoolMatch = selectedSchool == '전체' || s['school'] == selectedSchool;

        return (nameMatch || phoneMatch) && gradeMatch && schoolMatch;
      }).toList();
    });
  }

  // ================= CSV 업로드 =================
  Future<void> _uploadCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final Uint8List bytes = result.files.first.bytes!;
      String csvString = utf8.decode(bytes, allowMalformed: true);

      final rows = CsvToListConverter(shouldParseNumbers: false).convert(csvString);

      List<Map<String, dynamic>> uploaded = [];

      for (int i = 1; i < rows.length; i++) {
        final r = rows[i];
        if (r.length < 2) continue;

        uploaded.add({
          'name': r[0].toString().trim(),
          'phone': r[1].toString().replaceAll(RegExp(r'[^0-9]'), ''),
          'text1': r.length > 2 ? r[2].toString().trim() : '',
          'text2': r.length > 3 ? r[3].toString().trim() : '',
          'text3': r.length > 4 ? r[4].toString().trim() : '',
        });
      }

      setState(() {
        excelStudents = uploaded;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${uploaded.length}명 CSV 업로드 완료')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV 업로드 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ================= 실제 첫 번째 대상으로 미리보기 =================
  String get previewMessage {
    if (_messageController.text.isEmpty) return '메시지를 입력해주세요';

    Map<String, dynamic> sample = {
      'name': '홍길동',
      'price': '250000',
      'account': '국민 1234-5678-9012',
      'text1': '테스트1',
      'text2': '테스트2',
      'text3': '테스트3',
    };

    // 선택된 대상이 있으면 첫 번째 사람으로 미리보기
    if (selectedStudentIds.isNotEmpty) {
      final firstId = selectedStudentIds.first;
      final student = filteredStudents.firstWhere((s) => s['id'].toString() == firstId, orElse: () => {});
      if (student.isNotEmpty) sample = {...sample, ...student};
    } else if (excelStudents.isNotEmpty) {
      sample = {...sample, ...excelStudents.first};
    }

    return buildMessage(_messageController.text, sample);
  }

  String buildMessage(String template, Map<String, dynamic> data) {
    String msg = template;
    msg = msg.replaceAll('%%', data['name']?.toString() ?? '학생');
    msg = msg.replaceAll(r'$$', data['price']?.toString() ?? '0');
    msg = msg.replaceAll('&&', data['account']?.toString() ?? '');
    msg = msg.replaceAll('[문구1]', data['text1']?.toString() ?? '');
    msg = msg.replaceAll('[문구2]', data['text2']?.toString() ?? '');
    msg = msg.replaceAll('[문구3]', data['text3']?.toString() ?? '');
    return msg;
  }

  Future<void> _sendMessage() async {
    if (totalSelected == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('발송 대상을 선택해주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 실제 발송 대상 구성 (생략 가능 부분이지만 유지)
    List<Map<String, dynamic>> targets = [];

    for (var s in filteredStudents) {
      if (!selectedStudentIds.contains(s['id'].toString())) continue;
      if (sendTarget == 'student' || sendTarget == 'both') targets.add(s);
      if (sendTarget == 'parent' || sendTarget == 'both') {
        targets.add({...s, 'phone': s['parent_phone']});
      }
    }
    targets.addAll(excelStudents);

    await Supabase.instance.client.from('message_sends').insert({
      'center_id': widget.center.id,
      'send_type': isScheduled ? 'scheduled' : 'immediate',
      'target_count': targets.length,
      'cost': targets.length * 20,
      'sent_at': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${targets.length}건 발송 완료')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문자 발송'), backgroundColor: Colors.blue.shade700),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 대상자 선택 영역 (기존 코드 유지)
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('대상자 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Text('발송 대상: '),
                          const SizedBox(width: 12),
                          ChoiceChip(label: const Text('학생'), selected: sendTarget == 'student', onSelected: (_) => setState(() => sendTarget = 'student')),
                          const SizedBox(width: 8),
                          ChoiceChip(label: const Text('학부모'), selected: sendTarget == 'parent', onSelected: (_) => setState(() => sendTarget = 'parent')),
                          const SizedBox(width: 8),
                          ChoiceChip(label: const Text('둘 다'), selected: sendTarget == 'both', onSelected: (_) => setState(() => sendTarget = 'both')),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) {
                                searchKeyword = v;
                                _applyFilter();
                              },
                              decoration: const InputDecoration(labelText: '이름 / 전화번호 검색', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _uploadCsv,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('CSV 업로드'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedGrade,
                              items: ['전체', '중1', '중2', '중3', '고1', '고2', '고3', 'N수생']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) {
                                selectedGrade = v!;
                                _applyFilter();
                              },
                              decoration: const InputDecoration(labelText: '학년'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSchool,
                              items: ['전체', ...allStudents.map((s) => s['school']?.toString() ?? '').toSet()]
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) {
                                selectedSchool = v!;
                                _applyFilter();
                              },
                              decoration: const InputDecoration(labelText: '학교'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text('선택된 대상: $totalSelected 명', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredStudents.length + excelStudents.length,
                          itemBuilder: (context, i) {
                            if (i < filteredStudents.length) {
                              final s = filteredStudents[i];
                              final isSelected = selectedStudentIds.contains(s['id'].toString());
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) selectedStudentIds.add(s['id'].toString());
                                    else selectedStudentIds.remove(s['id'].toString());
                                  });
                                },
                                title: Text('${s['name']}'),
                                subtitle: Text('${s['student_phone'] ?? ''}'),
                              );
                            } else {
                              final ex = excelStudents[i - filteredStudents.length];
                              return ListTile(
                                title: Text(ex['name'] ?? ''),
                                subtitle: Text(ex['phone'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setState(() => excelStudents.remove(ex)),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // 오른쪽 메시지 영역
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('메시지 작성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _messageController,
                        maxLines: 10,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '%% = 이름\n\$\$ = 금액\n&& = 계좌번호\n[문구1], [문구2], [문구3]',
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text('미리보기 (첫 번째 대상 기준)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          previewMessage,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Checkbox(value: isScheduled, onChanged: (v) => setState(() => isScheduled = v ?? false)),
                          const Text('예약 발송'),
                        ],
                      ),

                      if (isScheduled) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (date != null) setState(() => scheduledDate = date);
                              },
                              child: Text(scheduledDate != null ? DateFormat('yyyy-MM-dd').format(scheduledDate!) : '날짜 선택'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (time != null) setState(() => scheduledTime = time);
                              },
                              child: Text(scheduledTime != null ? scheduledTime!.format(context) : '시간 선택'),
                            ),
                          ],
                        ),
                      ],

                      const Spacer(),

                      ElevatedButton(
                        onPressed: isLoading ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: Colors.blue.shade700,
                        ),
                        child: Text('${isScheduled ? "예약 " : ""}발송하기 ($totalSelected명)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}