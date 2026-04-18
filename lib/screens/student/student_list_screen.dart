import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  late TabController _tabController;
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select()
          .eq('center_id', widget.center.id)
          .order('name', ascending: true);

      setState(() {
        students = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // 학생 상세 화면에서 돌아올 때 새로고침
  Future<void> _refreshStudents() async {
    setState(() => isLoading = true);
    await _loadStudents();
  }

  List<Map<String, dynamic>> get filteredStudents {
    List<Map<String, dynamic>> list = students;

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((s) {
        final name = (s['name'] ?? '').toLowerCase();
        final phone = (s['phone'] ?? '').toLowerCase();
        final seat = (s['seat_number'] ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query) || seat.contains(query);
      }).toList();
    }

    final now = DateTime.now().toIso8601String().substring(0, 10);

    if (_tabController.index == 1) { // 재학생
      list = list.where((s) {
        final endDate = s['enrollment_end'];
        return endDate == null || endDate.toString().compareTo(now) >= 0;
      }).toList();
    } else if (_tabController.index == 2) { // 퇴원생
      list = list.where((s) {
        final endDate = s['enrollment_end'];
        return endDate != null && endDate.toString().compareTo(now) < 0;
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.center.displayName} 학생 목록'),
        backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '재학생'),
            Tab(text: '퇴원생'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '이름, 전화번호, 좌석번호 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStudentList(filteredStudents),
                      _buildStudentList(filteredStudents),
                      _buildStudentList(filteredStudents),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentRegisterScreen(center: widget.center),
            ),
          ).then((_) => _refreshStudents());   // 등록 후 새로고침
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildStudentList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(child: Text('해당 조건에 맞는 학생이 없습니다.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final student = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text((student['name'] ?? '?').substring(0, 1)),
            ),
            title: Text(student['name'] ?? '이름 없음'),
            subtitle: Text('${student['school'] ?? ''} • 좌석 ${student['seat_number'] ?? '-'}'),
            trailing: Text(student['phone'] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetailScreen(
                    student: student,
                    center: widget.center,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  _refreshStudents();   // 수정 후 새로고침
                }
              });
            },
          ),
        );
      },
    );
  }
}