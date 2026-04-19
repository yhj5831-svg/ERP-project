import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/center.dart';
import 'student_register_screen.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  final CenterModel center;

  const StudentListScreen({super.key, required this.center});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allStudents = [];
  bool isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select('id, name, student_phone, parent_phone, grade, school, seat_number, status, enrollment_start, enrollment_end, memo')
          .eq('center_id', widget.center.id)
          .order('name');

      setState(() {
        allStudents = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('학생 목록 로드 오류: $e');
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get activeStudents => allStudents.where((s) {
    final status = s['status']?.toString() ?? 'active';
    final endDateStr = s['enrollment_end']?.toString();
    final now = DateTime.now().toIso8601String().substring(0, 10);
    if (status == 'inactive') return false;
    if (endDateStr == null || endDateStr.isEmpty) return true;
    return endDateStr.compareTo(now) >= 0;
  }).toList();

  List<Map<String, dynamic>> get inactiveStudents => allStudents.where((s) {
    final status = s['status']?.toString() ?? 'active';
    final endDateStr = s['enrollment_end']?.toString();
    final now = DateTime.now().toIso8601String().substring(0, 10);
    if (status == 'inactive') return true;
    if (endDateStr == null || endDateStr.isEmpty) return false;
    return endDateStr.compareTo(now) < 0;
  }).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.center.displayName} 학생 관리'),
        backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '재원생'),
            Tab(text: '퇴원생'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTable(allStudents, '전체'),
                _buildTable(activeStudents, '재원생'),
                _buildTable(inactiveStudents, '퇴원생'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentRegisterScreen(center: widget.center)),
          ).then((_) => _loadStudents());
        },
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> students, String title) {
    if (students.isEmpty) {
      return Center(child: Text('$title 학생이 없습니다.', style: const TextStyle(color: Colors.grey)));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('상태')),
          DataColumn(label: Text('좌석')),
          DataColumn(label: Text('이름')),
          DataColumn(label: Text('학년')),
          DataColumn(label: Text('학교')),
          DataColumn(label: Text('학생전화')),
          DataColumn(label: Text('학부모전화')),
          DataColumn(label: Text('이용기간')),
          DataColumn(label: Text('D-Day')),
        ],
        rows: students.map((s) {
          final isActive = s['status'] == 'active';
          final endDateStr = s['enrollment_end']?.toString();
          final dday = _getDday(endDateStr);

          return DataRow(
            cells: [
              DataCell(Chip(
                label: Text(isActive ? '재원생' : '퇴원생'),
                backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
                labelStyle: TextStyle(color: isActive ? Colors.green : Colors.red),
              )),
              DataCell(Text(s['seat_number']?.toString() ?? '-')),
              DataCell(Text(s['name'] ?? '')),
              DataCell(Text(s['grade'] ?? '-')),
              DataCell(Text(s['school']?.toString() ?? '-')),
              DataCell(Text(s['student_phone']?.toString() ?? '-')),
              DataCell(Text(s['parent_phone']?.toString() ?? '-')),
              DataCell(Text(endDateStr != null ? endDateStr.substring(0, 10) : '무기한')),
              DataCell(Text(dday, style: TextStyle(
                color: dday.startsWith('D-') ? Colors.red : Colors.blue,
                fontWeight: FontWeight.bold,
              ))),
            ],
            onSelectChanged: (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetailScreen(
                    student: s,
                    center: widget.center,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}