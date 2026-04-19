import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/center.dart';
import '../sms/sms_send_screen.dart';

class MealManagementScreen extends StatefulWidget {
  final CenterModel center;

  const MealManagementScreen({super.key, required this.center});

  @override
  State<MealManagementScreen> createState() => _MealManagementScreenState();
}

class _MealManagementScreenState extends State<MealManagementScreen> {
  DateTime currentMonth = DateTime.now();
  List<Map<String, dynamic>> mealApplications = [];
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  int lunchPrice = 6000;
  int dinnerPrice = 7000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final monthStart = DateTime(currentMonth.year, currentMonth.month, 1);
    final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    final startStr = DateFormat('yyyy-MM-dd').format(monthStart);
    final endStr = DateFormat('yyyy-MM-dd').format(monthEnd);

    try {
      final appRes = await Supabase.instance.client
          .from('meal_applications')
          .select('*, students(name, seat_number)')
          .eq('center_id', widget.center.id)
          .gte('meal_date', startStr)
          .lte('meal_date', endStr);

      final studentRes = await Supabase.instance.client
          .from('students')
          .select('id, name, seat_number')
          .eq('center_id', widget.center.id)
          .eq('status', 'active');

      setState(() {
        mealApplications = List<Map<String, dynamic>>.from(appRes);
        students = List<Map<String, dynamic>>.from(studentRes);
        isLoading = false;
      });
    } catch (e) {
      print('급식 데이터 로드 오류: $e');
      setState(() => isLoading = false);
    }
  }

  Map<String, int> _getMealCount(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    int lunch = 0, dinner = 0;

    for (var app in mealApplications) {
      if (app['meal_date'] == dateStr) {
        if (app['lunch'] == true) lunch++;
        if (app['dinner'] == true) dinner++;
      }
    }
    return {'lunch': lunch, 'dinner': dinner};
  }

  Map<String, dynamic> _calculateStudentMeal(String studentId) {
    int lunchCount = 0;
    int dinnerCount = 0;

    for (var app in mealApplications) {
      if (app['student_id'] == studentId) {
        if (app['lunch'] == true) lunchCount++;
        if (app['dinner'] == true) dinnerCount++;
      }
    }

    final totalPrice = (lunchCount * lunchPrice) + (dinnerCount * dinnerPrice);

    return {
      'lunchCount': lunchCount,
      'dinnerCount': dinnerCount,
      'totalPrice': totalPrice,
    };
  }

  // 특정 날짜 상세 명단 보기
  void _showDailyDetail(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final lunchList = <String>[];
    final dinnerList = <String>[];

    for (var app in mealApplications) {
      if (app['meal_date'] == dateStr) {
        final name = app['students']?['name'] ?? '알 수 없음';
        if (app['lunch'] == true) lunchList.add(name);
        if (app['dinner'] == true) dinnerList.add(name);
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MM월 dd일 (E)', 'ko_KR').format(date)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lunchList.isNotEmpty) ...[
                const Text('중식', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ...lunchList.map((name) => Text('• $name')),
                const SizedBox(height: 12),
              ],
              if (dinnerList.isNotEmpty) ...[
                const Text('석식', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ...dinnerList.map((name) => Text('• $name')),
              ],
              if (lunchList.isEmpty && dinnerList.isEmpty)
                const Text('신청자가 없습니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  // 월별 급식비 안내 문자 발송
  void _sendMonthlyMealNotice() {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학생 데이터가 없습니다.')),
      );
      return;
    }

    String message = "안녕하세요.\n${DateFormat('yyyy년 MM월').format(currentMonth)} 급식비 안내드립니다.\n\n";

    for (var student in students) {
      final calc = _calculateStudentMeal(student['id']);
      if (calc['totalPrice'] > 0) {
        message += "${student['name']}님\n";
        message += "중식 ${calc['lunchCount']}회 + 석식 ${calc['dinnerCount']}회\n";
        message += "총 ${NumberFormat('#,###').format(calc['totalPrice'])}원\n\n";
      }
    }

    message += "납부 방법은 기존과 동일합니다.\n감사합니다.";

    // 문자 발송 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmsSendScreen(center: widget.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('급식 관리'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: _sendMonthlyMealNotice,
            tooltip: '월별 급식비 안내 문자',
          ),
        ],
      ),
      body: Column(
        children: [
          // 월 네비게이션
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => currentMonth = DateTime(currentMonth.year, currentMonth.month - 1));
                    _loadData();
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('yyyy년 MM월').format(currentMonth),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => currentMonth = DateTime(currentMonth.year, currentMonth.month + 1));
                    _loadData();
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 42,
                    itemBuilder: (context, index) {
                      final firstDay = DateTime(currentMonth.year, currentMonth.month, 1).weekday;
                      final day = index - firstDay + 1;

                      if (day < 1 || day > DateTime(currentMonth.year, currentMonth.month + 1, 0).day) {
                        return const SizedBox.shrink();
                      }

                      final date = DateTime(currentMonth.year, currentMonth.month, day);
                      final counts = _getMealCount(date);
                      final hasLunch = counts['lunch']! > 0;
                      final hasDinner = counts['dinner']! > 0;

                      return GestureDetector(
                        onTap: () => _showDailyDetail(date),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: (hasLunch || hasDinner) ? Colors.orange.shade50 : Colors.white,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (hasLunch || hasDinner) ...[
                                const SizedBox(height: 4),
                                if (hasLunch) const Text('중', style: TextStyle(fontSize: 12, color: Colors.blue)),
                                if (hasDinner) const Text('석', style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
                              ],
                            ],
                          ),
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