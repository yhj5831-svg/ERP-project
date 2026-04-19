import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/center.dart';
import '../schedule/schedule_management_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final CenterModel center;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.center,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  int _scheduleTabIndex = 0; // 0: 주별, 1: 월별

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final isActive = student['status'] == 'active';

    return Scaffold(
      appBar: AppBar(
        title: Text('${student['name']} 학생 상세'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== 1. 왼쪽: 학생 기본 정보 + 버튼 ====================
          Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        student['name'].toString().substring(0, 1),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      student['name'] ?? '',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(
                    child: Text(
                      student['grade'] ?? '',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _infoRow('학교', student['school'] ?? '-'),
                  _infoRow('좌석번호', student['seat_number'] ?? '-'),
                  _infoRow('학생 전화', student['student_phone'] ?? '-'),
                  _infoRow('학부모 전화', student['parent_phone'] ?? '-'),
                  _infoRow('상태', isActive ? '재원생' : '퇴원생', color: isActive ? Colors.green : Colors.red),
                  _infoRow('이용 종료일', student['enrollment_end']?.toString().substring(0, 10) ?? '무기한'),
                  _infoRow('D-Day', _getDday(student['enrollment_end']?.toString())),

                  const SizedBox(height: 40),

                  // ==================== 버튼 영역 ====================
                  ElevatedButton.icon(
                    onPressed: _resetPassword,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('비밀번호 초기화 (0000)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleManagementScreen(center: widget.center),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('스케줄 입력 / 변경'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================== 2. 중앙: 스케줄 ====================
          Expanded(
            flex: 2,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: '주별 스케줄'),
                      Tab(text: '월별 스케줄'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('주별 스케줄', style: TextStyle(fontSize: 20)),
                              Text('(준비중)', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('월별 스케줄', style: TextStyle(fontSize: 20)),
                              Text('(준비중)', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================== 3. 오른쪽: 메모 + 상담내역 (반반) ====================
          Expanded(
            child: Column(
              children: [
                // 메모 영역 (위쪽)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('메모 / 특이사항', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '여기에 학생에 대한 특이사항, 지적사항 등을 메모합니다.\n\n(추후 입력 기능 추가 예정)',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // 상담내역 영역 (아래쪽)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('상담내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            children: [
                              _consultationItem('2026-04-10', '소장 상담', '수학 성적이 저조. 집중력 향상 필요.'),
                              _consultationItem('2026-03-28', '실장 상담', '영어 단어 테스트 85점'),
                              _consultationItem('2026-03-15', '성적 상담', '중간고사 평균 78점'),
                              _consultationItem('2026-03-05', '소장 상담', '출석률 개선 필요'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consultationItem(String date, String type, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
        title: Text(type),
        subtitle: Text(content),
        trailing: Text(date, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ),
    );
  }

  String _getDday(String? endDateStr) {
    if (endDateStr == null || endDateStr.isEmpty) return '무기한';
    try {
      final endDate = DateTime.parse(endDateStr);
      final diff = endDate.difference(DateTime.now()).inDays;
      return diff >= 0 ? 'D+$diff' : 'D$diff';
    } catch (_) {
      return '-';
    }
  }

  // 비밀번호 초기화
  Future<void> _resetPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 초기화'),
        content: const Text('학생의 비밀번호를 초기 비밀번호 "0000"으로 초기화하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 0000으로 초기화되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}