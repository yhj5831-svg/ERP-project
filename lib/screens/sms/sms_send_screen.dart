import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/center.dart';

class SmsSendScreen extends StatefulWidget {
  final CenterModel center;

  const SmsSendScreen({super.key, required this.center});

  @override
  State<SmsSendScreen> createState() => _SmsSendScreenState();
}

class _SmsSendScreenState extends State<SmsSendScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  List<Map<String, dynamic>> selectedStudents = [];

  bool isLoading = true;
  bool isSending = false;

  // 발송 방식 선택 (추후 카톡 알림톡 중심으로 확장)
  String sendType = 'kakao'; // 'kakao' 또는 'sms'

  // 카카오 알림톡용 상용구 템플릿 (실제로는 템플릿 코드로 관리)
  final List<Map<String, String>> kakaoTemplates = [
    {
      'title': '등원 안내',
      'content': '안녕하세요 {이름}님.\n내일 등원 시간은 오후 2시입니다.\n감사합니다.',
    },
    {
      'title': '벌점 안내',
      'content': '안녕하세요 {이름}님.\n이번 주 벌점이 {벌점}점 누적되었습니다.\n확인 부탁드려요.',
    },
    {
      'title': '급식 신청 마감',
      'content': '안녕하세요 {이름}님.\n이번 주 급식 신청 마감이 오늘까지입니다.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select('id, name, phone, seat_number')
          .eq('center_id', widget.center.id)
          .eq('status', 'active')
          .order('name');

      setState(() {
        students = List<Map<String, dynamic>>.from(response);
        filteredStudents = List.from(students);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredStudents = List.from(students);
      } else {
        filteredStudents = students.where((s) {
          final name = (s['name'] ?? '').toLowerCase();
          final phone = (s['phone'] ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) || phone.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleStudent(Map<String, dynamic> student) {
    setState(() {
      if (selectedStudents.contains(student)) {
        selectedStudents.remove(student);
      } else {
        selectedStudents.add(student);
      }
    });
  }

  Future<void> _sendMessage() async {
    if (selectedStudents.isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수신자와 메시지를 입력해주세요.')),
      );
      return;
    }

    setState(() => isSending = true);

    try {
      // TODO: 실제 카카오 알림톡 API 연동 예정
      // 지금은 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 1500));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sendType == 'kakao'
                ? '${selectedStudents.length}명에게 카카오 알림톡이 발송되었습니다.'
                : '${selectedStudents.length}명에게 SMS가 발송되었습니다.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // 발송 기록 저장 (추후 로그 테이블에 저장 가능)
      setState(() {
        isSending = false;
        _messageController.clear();
        selectedStudents.clear();
      });
    } catch (e) {
      setState(() => isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('발송 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메시지 발송'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // 발송 방식 선택 (카톡 우선)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'kakao', label: Text('카카오 알림톡')),
                ButtonSegment(value: 'sms', label: Text('SMS')),
              ],
              selected: {sendType},
              onSelectionChanged: (Set<String> selection) {
                setState(() => sendType = selection.first);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '이름 또는 전화번호 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterStudents,
            ),
          ),

          if (selectedStudents.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Text('${selectedStudents.length}명 선택됨', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => selectedStudents.clear()),
                    child: const Text('전체 해제'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final isSelected = selectedStudents.contains(student);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleStudent(student),
                        title: Text(student['name'] ?? ''),
                        subtitle: Text(student['phone'] ?? ''),
                        secondary: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text((student['name'] ?? '?').substring(0, 1)),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 상용구 버튼
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: kakaoTemplates.map((template) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: () => _messageController.text = template['content']!,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200]),
                          child: Text(template['title']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '발송할 메시지를 입력하세요...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: isSending ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sendType == 'kakao' ? Colors.amber.shade700 : Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          sendType == 'kakao' ? '카카오 알림톡 발송하기' : 'SMS 발송하기',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}