import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/center.dart';

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
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _schoolController;
  late TextEditingController _seatNumberController;
  late TextEditingController _memoController;
  late TextEditingController _enrollmentStartController;
  late TextEditingController _enrollmentEndController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student['name']);
    _phoneController = TextEditingController(text: widget.student['phone']);
    _birthDateController = TextEditingController(text: widget.student['birth_date']);
    _schoolController = TextEditingController(text: widget.student['school']);
    _seatNumberController = TextEditingController(text: widget.student['seat_number']);
    _memoController = TextEditingController(text: widget.student['memo']);
    _enrollmentStartController = TextEditingController(text: widget.student['enrollment_start']);
    _enrollmentEndController = TextEditingController(text: widget.student['enrollment_end']);
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('students').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birth_date': _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
        'school': _schoolController.text.trim(),
        'seat_number': _seatNumberController.text.trim(),
        'memo': _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        'enrollment_start': _enrollmentStartController.text.trim().isEmpty ? null : _enrollmentStartController.text.trim(),
        'enrollment_end': _enrollmentEndController.text.trim().isEmpty ? null : _enrollmentEndController.text.trim(),
      }).eq('id', widget.student['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학생 정보가 수정되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 수정 성공 신호와 함께 이전 화면으로 돌아감
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 초기화'),
        content: const Text('학생의 비밀번호를 0000으로 초기화하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('비밀번호가 0000으로 초기화되었습니다.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 상세 정보'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '학생 이름 *'),
                  validator: (value) => value!.isEmpty ? '이름을 입력해주세요' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: '전화번호 *'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? '전화번호를 입력해주세요' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _birthDateController,
                  decoration: const InputDecoration(labelText: '생년월일 (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _schoolController,
                  decoration: const InputDecoration(labelText: '학교 *'),
                  validator: (value) => value!.isEmpty ? '학교를 입력해주세요' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _seatNumberController,
                  decoration: const InputDecoration(labelText: '좌석번호 *'),
                  validator: (value) => value!.isEmpty ? '좌석번호를 입력해주세요' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _enrollmentStartController,
                  decoration: const InputDecoration(labelText: '입학(등록) 날짜 (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _enrollmentEndController,
                  decoration: const InputDecoration(labelText: '퇴원 예정일 (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _memoController,
                  decoration: const InputDecoration(labelText: '메모'),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateStudent,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('정보 수정하기'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('비밀번호 초기화'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}