import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/center.dart';

class PenaltyManagementScreen extends StatefulWidget {
  final CenterModel center;

  const PenaltyManagementScreen({super.key, required this.center});

  @override
  State<PenaltyManagementScreen> createState() => _PenaltyManagementScreenState();
}

class _PenaltyManagementScreenState extends State<PenaltyManagementScreen> {
  List<Map<String, dynamic>> penalties = [];
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  final _reasonController = TextEditingController();
  int selectedPoints = 5;
  String? selectedStudentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // 학생 목록
      final studentRes = await Supabase.instance.client
          .from('students')
          .select('id, name, seat_number')
          .eq('center_id', widget.center.id)
          .eq('status', 'active')
          .order('name');

      // 벌점 목록
      final penaltyRes = await Supabase.instance.client
          .from('penalties')
          .select('*, students(name, seat_number)')
          .eq('center_id', widget.center.id)
          .order('created_at', ascending: false);

      setState(() {
        students = List<Map<String, dynamic>>.from(studentRes);
        penalties = List<Map<String, dynamic>>.from(penaltyRes);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addPenalty() async {
    if (selectedStudentId == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학생과 사유를 입력해주세요.')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('penalties').insert({
        'center_id': widget.center.id,
        'student_id': selectedStudentId,
        'points': selectedPoints,
        'reason': _reasonController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('벌점이 부여되었습니다.'), backgroundColor: Colors.red),
      );

      _reasonController.clear();
      selectedStudentId = null;
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('벌점 부여 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('벌점 관리'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 벌점 부여 폼
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedStudentId,
                            decoration: const InputDecoration(labelText: '학생 선택'),
                            items: students.map((s) {
                              return DropdownMenuItem(
                                value: s['id'],
                                child: Text('${s['name']} (${s['seat_number'] ?? '-'})'),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => selectedStudentId = value),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('벌점'),
                              const SizedBox(width: 12),
                              DropdownButton<int>(
                                value: selectedPoints,
                                items: [1, 3, 5, 10, 15].map((p) => DropdownMenuItem(value: p, child: Text('$p점'))).toList(),
                                onChanged: (value) => setState(() => selectedPoints = value!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _reasonController,
                            decoration: const InputDecoration(labelText: '사유'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addPenalty,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('벌점 부여하기'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 기존 벌점 목록
                Expanded(
                  child: penalties.isEmpty
                      ? const Center(child: Text('등록된 벌점이 없습니다.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: penalties.length,
                          itemBuilder: (context, index) {
                            final p = penalties[index];
                            final student = p['students'] ?? {};
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text('${student['name']} - ${p['points']}점'),
                                subtitle: Text(p['reason'] ?? ''),
                                trailing: Text(p['created_at'].toString().substring(0, 10)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}