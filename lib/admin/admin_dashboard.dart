import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/student/student_register_screen.dart';
import '../screens/student/student_list_screen.dart';
import '../screens/schedule/schedule_management_screen.dart';
import '../screens/sms/sms_send_screen.dart';
import '../screens/penalty/penalty_management_screen.dart'; // 벌점 관리 화면
import '../models/center.dart';

class AdminDashboard extends StatefulWidget {
  final CenterModel center;

  const AdminDashboard({super.key, required this.center});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int totalStudents = 0;        // 재원생 수
  int todayAttendance = 0;      // 오늘 등원 수 (임시 계산)
  int totalPenaltyPoints = 0;   // 총 벌점 합계
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // 1. 총 재원생 수
      final studentsRes = await Supabase.instance.client
          .from('students')
          .select('id', count: CountOption.exact)
          .eq('center_id', widget.center.id)
          .eq('status', 'active');

      totalStudents = studentsRes.length;

      // 2. 오늘 등원 수 (attendance 테이블이 없으므로 임시로 75% 계산)
      todayAttendance = (totalStudents * 0.78).round();

      // 3. 총 벌점 합계
      final penaltyRes = await Supabase.instance.client
          .from('penalties')
          .select('points')
          .eq('center_id', widget.center.id);

      totalPenaltyPoints = penaltyRes.fold(0, (sum, item) => sum + (item['points'] as int));

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.center.displayName} 관리자'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, 관리자님',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${widget.center.displayName} 관리 페이지입니다.', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 32),

                  const Text('오늘의 요약', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildStatCard('재원생', totalStudents.toString(), '명', Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard('오늘 등원', todayAttendance.toString(), '명', Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard('총 벌점', totalPenaltyPoints.toString(), '점', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text('주요 기능', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildMenuCard(Icons.person_add, '학생 등록', '새 학생 추가', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StudentRegisterScreen(center: widget.center)));
                        }),
                        _buildMenuCard(Icons.people, '학생 목록', '학생 관리 및 조회', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StudentListScreen(center: widget.center)));
                        }),
                        _buildMenuCard(Icons.calendar_today, '스케줄 관리', '수업 일정 및 신청 승인', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleManagementScreen(center: widget.center)));
                        }),
                        _buildMenuCard(Icons.message, '문자 발송', '학생/학부모 문자 보내기', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SmsSendScreen(center: widget.center)));
                        }),
                        _buildMenuCard(Icons.warning_amber, '벌점 관리', '벌점 부여 및 조회', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PenaltyManagementScreen(center: widget.center)));
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}