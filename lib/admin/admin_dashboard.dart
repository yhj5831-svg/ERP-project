import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/center.dart';

// 모든 화면 import (정확한 경로)
import '../../screens/student/student_list_screen.dart';
import '../../screens/schedule/schedule_management_screen.dart';
import '../../screens/penalty/penalty_management_screen.dart';
import '../../screens/meal/meal_management_screen.dart';
import '../../screens/sms/sms_send_screen.dart';

class AdminDashboard extends StatefulWidget {
  final CenterModel center;

  const AdminDashboard({super.key, required this.center});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int totalStudents = 0;
  int maleStudents = 0;
  int femaleStudents = 0;
  int todayAttendance = 0;

  List<Map<String, dynamic>> todaySchedules = [];
  bool _isLoadingTimeline = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadTodaySchedules();
  }

  Future<void> _loadDashboardData() async {
    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('id, gender')
          .eq('center_id', widget.center.id)
          .eq('status', 'active');

      setState(() {
        totalStudents = res.length;
        maleStudents = res.where((s) => s['gender'] == 'male').length;
        femaleStudents = res.where((s) => s['gender'] == 'female').length;
        todayAttendance = (totalStudents * 0.85).round();
      });
    } catch (e) {
      print('통계 로드 실패: $e');
    }
  }

  Future<void> _loadTodaySchedules() async {
    setState(() => _isLoadingTimeline = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final res = await Supabase.instance.client
          .from('schedules')
          .select('*, student:students(name, seat_number)')
          .eq('center_id', widget.center.id)
          .eq('schedule_date', today)
          .order('start_time');

      setState(() {
        todaySchedules = List<Map<String, dynamic>>.from(res);
        _isLoadingTimeline = false;
      });
    } catch (e) {
      print('스케줄 로드 실패: $e');
      setState(() => _isLoadingTimeline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.center.name} 관리자 대시보드'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Row(
        children: [
          // ==================== 왼쪽: 통계 + 메뉴 ====================
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatCard('재원생', totalStudents.toString(), Icons.people),
                      const SizedBox(width: 16),
                      _buildStatCard('남학생', maleStudents.toString(), Icons.male),
                      const SizedBox(width: 16),
                      _buildStatCard('여학생', femaleStudents.toString(), Icons.female),
                      const SizedBox(width: 16),
                      _buildStatCard('오늘 등원', todayAttendance.toString(), Icons.check_circle),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text('주요 기능', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      children: [
                        _buildMenuCard('학생 관리', Icons.school, Colors.blue, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StudentListScreen(center: widget.center)));
                        }),
                        _buildMenuCard('스케줄 관리', Icons.calendar_today, Colors.green, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleManagementScreen(center: widget.center)));
                        }),
                        _buildMenuCard('벌점 관리', Icons.warning_amber_rounded, Colors.orange, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PenaltyManagementScreen(center: widget.center)));
                        }),
                        _buildMenuCard('급식 관리', Icons.restaurant, Colors.purple, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MealManagementScreen(center: widget.center)));
                        }),
                        _buildMenuCard('문자 발송', Icons.message, Colors.teal, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SmsSendScreen(center: widget.center)));
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================== 오른쪽: 오늘 하루 타임라인 ====================
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(DateTime.now()),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text('일별 전체 조회', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_isLoadingTimeline)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
                  else if (todaySchedules.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 80, color: Colors.white38),
                            SizedBox(height: 16),
                            Text('오늘 등록된 스케줄이 없습니다.', style: TextStyle(color: Colors.white70, fontSize: 18)),
                            Text('스케줄 관리에서 먼저 입력해주세요.', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: todaySchedules.map((schedule) {
                            final student = schedule['student'] ?? {};
                            final startTime = (schedule['start_time'] ?? '').toString().substring(0, 5);
                            final type = schedule['type'] ?? '수업';

                            return _buildTimelineSlot(
                              startTime,
                              type,
                              _getIconForType(type),
                              student['name'] ?? '알 수 없음',
                              student['seat_number'] ?? '-',
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue.shade700, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 15, color: Colors.grey)),
            Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSlot(String time, String type, IconData icon, String studentName, String seat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2937),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('$seat $studentName', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Checkbox(value: false, onChanged: (val) {}, side: const BorderSide(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type.contains('등원') || type.contains('입실')) return Icons.login;
    if (type.contains('하원') || type.contains('퇴실')) return Icons.logout;
    if (type.contains('복귀') || type.contains('외출')) return Icons.refresh;
    return Icons.school;
  }
}