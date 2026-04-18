import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/center.dart';

class StudentRegisterScreen extends StatefulWidget {
  final CenterModel center;

  const StudentRegisterScreen({super.key, required this.center});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _schoolController = TextEditingController();
  final _seatNumberController = TextEditingController();
  final _memoController = TextEditingController();
  final _enrollmentStartController = TextEditingController();
  final _enrollmentEndController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('students').insert({
        'center_id': widget.center.id,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birth_date': _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
        'school': _schoolController.text.trim(),
        'seat_number': _seatNumberController.text.trim(),
        'memo': _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        'enrollment_start': _enrollmentStartController.text.trim().isEmpty ? null : _enrollmentStartController.text.trim(),
        'enrollment_end': _enrollmentEndController.text.trim().isEmpty ? null : _enrollmentEndController.text.trim(),
        'status': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학생이 성공적으로 등록되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 입력 필드 초기화
      _nameController.clear();
      _phoneController.clear();
      _birthDateController.clear();
      _schoolController.clear();
      _seatNumberController.clear();
      _memoController.clear();
      _enrollmentStartController.clear();
      _enrollmentEndController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('등록 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 등록'),
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
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerStudent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('학생 등록하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}