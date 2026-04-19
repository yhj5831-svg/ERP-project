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
  List<Map<String, dynamic>> activeStudents = [];
  List<Map<String, dynamic>> penalties = [];
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
      final now = DateTime.now().toIso8601String().substring(0, 10); // 오늘 날짜 (YYYY-MM-DD)

      // 재원생 필터링: enrollment_end가 null이거나 오늘 이후인 학생
      final studentRes = await Supabase.instance.client
          .from('students')
          .select('id, name, seat_number, status, enrollment_end')
          .eq('center_id', widget.center.id)
          .order('name');

      // 이용기간 + status 기준으로 재원생만 필터링
      final filtered = studentRes.where((s) {
        final status = s['status']?.toString() ?? 'active';
        final endDateStr = s['enrollment_end']?.toString();

        if (status == 'inactive') return false;

        if (endDateStr == null || endDateStr.isEmpty) return true; // 이용기간 없으면 재원생

        // enrollment_end가 오늘 이후이면 재원생
        return endDateStr.compareTo(now) >= 0;
      }).toList();

      // 벌점 내역
      final penaltyRes = await Supabase.instance.client
          .from('penalties')
          .select('*, students(name, seat_number)')
          .eq('center_id', widget.center.id)
          .order('created_at', ascending: false);

      setState(() {
        activeStudents = List<Map<String, dynamic>>.from(filtered);
        penalties = List<Map<String, dynamic>>.from(penaltyRes);
        isLoading = false;
      });

      print('✅ 재원생 필터링 완료 - 총 ${activeStudents.length}명');
      for (var s in activeStudents) {
        print('   학생: ${s['name']} | enrollment_end: ${s['enrollment_end']} | status: ${s['status']}');
      }

    } catch (e) {
      print('❌ 데이터 로드 실패: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _addPenalty() async {
    final studentId = selectedStudentId;
    final reason = _reasonController.text.trim();

    if (studentId == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학생을 선택하고 사유를 입력해주세요.')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('penalties').insert({
        'center_id': widget.center.id,
        'student_id': studentId,
        'points': selectedPoints,
        'reason': reason,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedPoints}점 벌점이 부여되었습니다.'),
          backgroundColor: Colors.red.shade700,
        ),
      );

      _reasonController.clear();
      setState(() {
        selectedStudentId = null;
        selectedPoints = 5;
      });

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('벌점 등록 실패: $e'), backgroundColor: Colors.red),
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
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('새 벌점 부여', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),

                              DropdownButtonFormField<String>(
                                value: selectedStudentId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: '학생 선택 (재원생)',
                                  border: OutlineInputBorder(),
                                ),
                                hint: const Text('재원생을 선택하세요'),
                                items: activeStudents.map((s) {
                                  final endDate = s['enrollment_end']?.toString() ?? '무기한';
                                  return DropdownMenuItem<String>(
                                    value: s['id'] as String,
                                    child: Text('${s['name']} (${s['seat_number'] ?? '-'}) - ${endDate}'),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => selectedStudentId = value),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  const Text('벌점', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 20),
                                  DropdownButton<int>(
                                    value: selectedPoints,
                                    items: [1, 3, 5, 10, 15, 20].map((p) => DropdownMenuItem<int>(
                                      value: p,
                                      child: Text('$p점'),
                                    )).toList(),
                                    onChanged: (value) {
                                      if (value != null) setState(() => selectedPoints = value);
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              TextField(
                                controller: _reasonController,
                                decoration: const InputDecoration(
                                  labelText: '사유',
                                  hintText: '지각, 숙제 미제출 등',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _addPenalty,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('벌점 부여하기', style: TextStyle(fontSize: 17)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('벌점 내역', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('총 ${penalties.length}건', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),

                    if (penalties.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('등록된 벌점이 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: penalties.length,
                        itemBuilder: (context, index) {
                          final p = penalties[index];
                          final student = p['students'] ?? {};
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade100,
                                child: Text('${p['points']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(student['name'] ?? '알 수 없음'),
                              subtitle: Text(p['reason'] ?? ''),
                              trailing: Text(
                                p['created_at'].toString().substring(0, 10),
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}