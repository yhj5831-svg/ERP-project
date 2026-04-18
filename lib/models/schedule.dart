class ScheduleModel {
  final String id;
  final String centerId;
  final String studentId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? memo;
  final bool isRecurring;
  final String? recurrenceType;     // 'daily', 'weekly'
  final DateTime? recurrenceEndDate;
  final String status;              // 'active', 'pending_change', 'cancelled'

  ScheduleModel({
    required this.id,
    required this.centerId,
    required this.studentId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.memo,
    this.isRecurring = false,
    this.recurrenceType,
    this.recurrenceEndDate,
    this.status = 'active',
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      centerId: json['center_id'],
      studentId: json['student_id'],
      title: json['title'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      memo: json['memo'],
      isRecurring: json['is_recurring'] ?? false,
      recurrenceType: json['recurrence_type'],
      recurrenceEndDate: json['recurrence_end_date'] != null 
          ? DateTime.parse(json['recurrence_end_date']) 
          : null,
      status: json['status'] ?? 'active',
    );
  }
}