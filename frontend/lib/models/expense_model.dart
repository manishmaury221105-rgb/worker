class ExpenseModel {
  final String id;
  final String userId;
  final String category; // 'TRAVEL', 'FOOD', 'MATERIALS', 'TOOLS', 'FUEL', 'OTHER'
  final double amount;
  final String description;
  final String? receiptUrl;
  final DateTime expenseDate;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED', 'REIMBURSED'
  final String? adminComment;
  final DateTime createdAt;
  final String? workerName;
  final String? workerPhone;
  final String? department;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.description,
    this.receiptUrl,
    required this.expenseDate,
    required this.status,
    this.adminComment,
    required this.createdAt,
    this.workerName,
    this.workerPhone,
    this.department,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isReimbursed => status == 'REIMBURSED';

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return ExpenseModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      category: json['category'] ?? 'OTHER',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      receiptUrl: json['receiptUrl'],
      expenseDate: DateTime.tryParse(json['expenseDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'PENDING',
      adminComment: json['adminComment'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      workerName: user?['name'],
      workerPhone: user?['phone'],
      department: user?['department'],
    );
  }
}
