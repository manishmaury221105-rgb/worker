class SalaryRecordModel {
  final String id;
  final String userId;
  final int month;
  final int year;
  final double baseSalary;
  final double allowance;
  final double deductions;
  final double netSalary;
  final int presentDays;
  final int absentDays;
  final double totalWorkingHours;
  final String status; // 'DRAFT', 'PENDING', 'PAID'
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? notes;
  final String? workerName;
  final String? workerPhone;
  final String? department;
  final String? designation;
  final String? bankAccount;
  final String? upiId;

  SalaryRecordModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.baseSalary,
    required this.allowance,
    required this.deductions,
    required this.netSalary,
    required this.presentDays,
    required this.absentDays,
    required this.totalWorkingHours,
    required this.status,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
    this.workerName,
    this.workerPhone,
    this.department,
    this.designation,
    this.bankAccount,
    this.upiId,
  });

  bool get isPaid => status == 'PAID';

  factory SalaryRecordModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return SalaryRecordModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? 2026,
      baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0.0,
      allowance: (json['allowance'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0.0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      totalWorkingHours: (json['totalWorkingHours'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      paymentDate: json['paymentDate'] != null ? DateTime.tryParse(json['paymentDate']) : null,
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
      workerName: user?['name'],
      workerPhone: user?['phone'],
      department: user?['department'],
      designation: user?['designation'],
      bankAccount: user?['bankAccount'],
      upiId: user?['upiId'],
    );
  }
}

class SalaryAdvanceModel {
  final String id;
  final String userId;
  final double amount;
  final String reason;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED', 'DEDUCTED'
  final String? adminComment;
  final DateTime requestDate;
  final DateTime? payoutDate;
  final String? workerName;
  final String? workerPhone;
  final String? department;

  SalaryAdvanceModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.status,
    this.adminComment,
    required this.requestDate,
    this.payoutDate,
    this.workerName,
    this.workerPhone,
    this.department,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';

  factory SalaryAdvanceModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return SalaryAdvanceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      adminComment: json['adminComment'],
      requestDate: DateTime.tryParse(json['requestDate'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      payoutDate: json['payoutDate'] != null ? DateTime.tryParse(json['payoutDate']) : null,
      workerName: user?['name'],
      workerPhone: user?['phone'],
      department: user?['department'],
    );
  }
}
