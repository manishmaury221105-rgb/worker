class LeaveModel {
  final String id;
  final String userId;
  final String leaveType; // 'SICK', 'CASUAL', 'EMERGENCY', 'PAID', 'UNPAID'
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final String? adminComment;
  final DateTime createdAt;
  final String? workerName;
  final String? workerPhone;
  final String? department;

  LeaveModel({
    required this.id,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.adminComment,
    required this.createdAt,
    this.workerName,
    this.workerPhone,
    this.department,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return LeaveModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      leaveType: json['leaveType'] ?? 'CASUAL',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      totalDays: json['totalDays'] ?? 1,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      adminComment: json['adminComment'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      workerName: user?['name'],
      workerPhone: user?['phone'],
      department: user?['department'],
    );
  }
}
