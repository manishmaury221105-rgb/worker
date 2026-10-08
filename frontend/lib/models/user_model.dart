class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'ADMIN' or 'WORKER'
  final String department;
  final String designation;
  final double monthlySalary;
  final double hourlyRate;
  final String status; // 'ACTIVE' or 'INACTIVE'
  final String? avatarUrl;
  final String? address;
  final String? emergencyContact;
  final String? bankAccount;
  final String? upiId;
  final String? aadhaarNumber;
  final String? aadhaarFrontUrl;
  final String? aadhaarBackUrl;
  final DateTime? dateOfJoining;
  final int? unreadNotificationsCount;
  final int? activeTasksCount;
  final int? pendingLeavesCount;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.designation,
    required this.monthlySalary,
    required this.hourlyRate,
    required this.status,
    this.avatarUrl,
    this.address,
    this.emergencyContact,
    this.bankAccount,
    this.upiId,
    this.aadhaarNumber,
    this.aadhaarFrontUrl,
    this.aadhaarBackUrl,
    this.dateOfJoining,
    this.unreadNotificationsCount,
    this.activeTasksCount,
    this.pendingLeavesCount,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isActive => status == 'ACTIVE';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'WORKER',
      department: json['department'] ?? 'General',
      designation: json['designation'] ?? 'Worker',
      monthlySalary: (json['monthlySalary'] as num?)?.toDouble() ?? 20000.0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 100.0,
      status: json['status'] ?? 'ACTIVE',
      avatarUrl: json['avatarUrl'],
      address: json['address'],
      emergencyContact: json['emergencyContact'],
      bankAccount: json['bankAccount'],
      upiId: json['upiId'],
      aadhaarNumber: json['aadhaarNumber'],
      aadhaarFrontUrl: json['aadhaarFrontUrl'],
      aadhaarBackUrl: json['aadhaarBackUrl'],
      dateOfJoining: json['dateOfJoining'] != null
          ? DateTime.tryParse(json['dateOfJoining'])
          : null,
      unreadNotificationsCount: json['unreadNotificationsCount'],
      activeTasksCount: json['activeTasksCount'],
      pendingLeavesCount: json['pendingLeavesCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department,
      'designation': designation,
      'monthlySalary': monthlySalary,
      'hourlyRate': hourlyRate,
      'status': status,
      'avatarUrl': avatarUrl,
      'address': address,
      'emergencyContact': emergencyContact,
      'bankAccount': bankAccount,
      'upiId': upiId,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarFrontUrl': aadhaarFrontUrl,
      'aadhaarBackUrl': aadhaarBackUrl,
      'dateOfJoining': dateOfJoining?.toIso8601String(),
    };
  }
}
