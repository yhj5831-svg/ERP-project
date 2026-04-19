import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _studentPhoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _seatNumberController = TextEditingController();
  final _memoController = TextEditingController();

  String? selectedGrade;
  String? selectedSchool;
  final _otherSchoolController = TextEditingController();

  bool isLoading = false;

  // ==================== 각 센터별 실제 주요 학교 리스트 (정식 풀네임) ====================
  late final List<String> schoolList;

  @override
  void initState() {
    super.initState();
    schoolList = _getSchoolListByCenter(widget.center.id);
  }

  List<String> _getSchoolListByCenter(String centerId) {
    switch (centerId) {
      // 1. 대치본원 - 강남/서초/송파/강동 중심
      case 'thats1_main':
        return [
          '대치중학교', '은광여자중학교', '휘문중학교', '압구정중학교', '도곡중학교', '개포중학교',
          '삼성중학교', '신사중학교', '청담중학교', '대청중학교', '역삼중학교', '언주중학교',
          '대치고등학교', '휘문고등학교', '은광여자고등학교', '서울고등학교', '숙명여자고등학교',
          '중동고등학교', '영동고등학교', '청담고등학교', '강남고등학교', '세화여자고등학교',
          '한가람고등학교', '서울과학고등학교', '민족사관고등학교', '하나고등학교', '상산고등학교',
          '경기고등학교', '반포고등학교', '서초고등학교', '양재고등학교', '방배고등학교',
          '진선여자고등학교', '동덕여자고등학교', '기타 (직접 입력)',
        ];

      // 2. 송도센터 - 송도 + 연수 + 청라 + 주변 지역 중심
      case 'thats1_sd':
        return [
          '송도중학교', '송도국제중학교', '연수중학교', '청라중학교', '인천중학교', '학익중학교',
          '문학중학교', '인하중학교', '연수고등학교', '송도고등학교', '청라국제고등학교',
          '인천과학고등학교', '인천외국어고등학교', '인하대학교부속고등학교', '해송고등학교',
          '인천전자마이스터고등학교', '인천국제고등학교', '연수여자고등학교', '인천여자고등학교',
          '인천남고등학교', '인천고등학교', '인천제일고등학교', '인천동고등학교', '인천서고등학교',
          '인천북고등학교', '청라달빛고등학교', '기타 (직접 입력)',
        ];

      // 3. 해운대센터 - 해운대 + 기장 + 동래 + 수영 중심
      case 'thats1_hwd':
        return [
          '해운대중학교', '센텀중학교', '반여중학교', '재송중학교', '동래중학교', '수영중학교',
          '해운대고등학교', '부산고등학교', '센텀고등학교', '부산과학고등학교', '부산외국어고등학교',
          '기장고등학교', '해운대여자고등학교', '동래고등학교', '부산여자고등학교', '경남고등학교',
          '부산국제고등학교', '부산예술고등학교', '부산동고등학교', '부산진고등학교', '기타 (직접 입력)',
        ];

      // 4. 세종센터 - 세종시 전체 주요 학교
      case 'thats1_sj':
        return [
          '세종중학교', '한솔중학교', '나성중학교', '도담중학교', '아름중학교', '종촌중학교',
          '새롬중학교', '다정중학교', '소담중학교', '세종고등학교', '세종과학고등학교',
          '세종외국어고등학교', '세종예술고등학교', '한림고등학교', '영훈고등학교',
          '세종국제고등학교', '세종하이텍고등학교', '기타 (직접 입력)',
        ];

      default:
        return ['기타 (직접 입력)'];
    }
  }
  // =====================================================================

  void _formatPhone(TextEditingController controller, String text) {
    String digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';

    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학년을 선택해주세요.')),
      );
      return;
    }

    final schoolName = selectedSchool == '기타 (직접 입력)' 
        ? _otherSchoolController.text.trim() 
        : selectedSchool;

    if (schoolName == null || schoolName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학교를 선택하거나 입력해주세요.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await Supabase.instance.client.from('students').insert({
        'center_id': widget.center.id,
        'name': _nameController.text.trim(),
        'student_phone': _studentPhoneController.text.trim(),
        'parent_phone': _parentPhoneController.text.trim(),
        'grade': selectedGrade,
        'school': schoolName,
        'seat_number': _seatNumberController.text.trim(),
        'memo': _memoController.text.trim(),
        'status': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학생 등록이 완료되었습니다.'), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 등록'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '학생 이름 *'),
                      validator: (value) => value!.trim().isEmpty ? '이름을 입력해주세요' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _studentPhoneController,
                      decoration: const InputDecoration(labelText: '학생 전화번호 *'),
                      keyboardType: TextInputType.phone,
                      onChanged: (text) => _formatPhone(_studentPhoneController, text),
                      validator: (value) => value!.trim().isEmpty ? '학생 전화번호를 입력해주세요' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _parentPhoneController,
                      decoration: const InputDecoration(labelText: '학부모 전화번호 *'),
                      keyboardType: TextInputType.phone,
                      onChanged: (text) => _formatPhone(_parentPhoneController, text),
                      validator: (value) => value!.trim().isEmpty ? '학부모 전화번호를 입력해주세요' : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedGrade,
                      decoration: const InputDecoration(labelText: '학년 *'),
                      items: const [
                        DropdownMenuItem(value: '중1', child: Text('중1')),
                        DropdownMenuItem(value: '중2', child: Text('중2')),
                        DropdownMenuItem(value: '중3', child: Text('중3')),
                        DropdownMenuItem(value: '고1', child: Text('고1')),
                        DropdownMenuItem(value: '고2', child: Text('고2')),
                        DropdownMenuItem(value: '고3', child: Text('고3')),
                        DropdownMenuItem(value: 'N수생', child: Text('N수생')),
                      ],
                      onChanged: (value) => setState(() => selectedGrade = value),
                      validator: (value) => value == null ? '학년을 선택해주세요' : null,
                    ),
                    const SizedBox(height: 16),

                    // 학교 검색 기능 (Autocomplete)
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return schoolList.where((school) =>
                            school.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) {
                        setState(() {
                          selectedSchool = selection;
                          if (selection != '기타 (직접 입력)') {
                            _otherSchoolController.clear();
                          }
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: '학교 검색 *',
                            border: OutlineInputBorder(),
                            hintText: '학교 이름을 검색하세요 (예: 송도, 대치, 해운대)',
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty) 
                              ? '학교를 검색하거나 선택해주세요' 
                              : null,
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    if (selectedSchool == '기타 (직접 입력)')
                      TextFormField(
                        controller: _otherSchoolController,
                        decoration: const InputDecoration(
                          labelText: '학교명 직접 입력',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (selectedSchool == '기타 (직접 입력)' && (value == null || value.trim().isEmpty))
                            ? '학교명을 입력해주세요' 
                            : null,
                      ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _seatNumberController,
                      decoration: const InputDecoration(labelText: '좌석번호'),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _memoController,
                      decoration: const InputDecoration(labelText: '메모'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _registerStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                        ),
                        child: const Text('학생 등록하기', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}