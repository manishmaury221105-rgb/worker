class AttendanceModel {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkInTime;
  final double? checkInLat;
  final double? checkInLng;
  final String? checkInAddress;
  final DateTime? checkOutTime;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? checkOutAddress;
  final double workingHours;
  final String status; // 'PRESENT', 'ABSENT', 'LATE', 'HALF_DAY', 'ON_LEAVE'
  final String? notes;
  final String? workerName;
  final String? department;
  final String? designation;
  final bool isLocked;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    this.checkInTime,
    this.checkInLat,
    this.checkInLng,
    this.checkInAddress,
    this.checkOutTime,
    this.checkOutLat,
    this.checkOutLng,
    this.checkOutAddress,
    required this.workingHours,
    required this.status,
    this.notes,
    this.workerName,
    this.department,
    this.designation,
    this.isLocked = false,
  });

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return AttendanceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      checkInTime: json['checkInTime'] != null
          ? DateTime.tryParse(json['checkInTime'])
          : null,
      checkInLat: (json['checkInLat'] as num?)?.toDouble(),
      checkInLng: (json['checkInLng'] as num?)?.toDouble(),
      checkInAddress: json['checkInAddress'],
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.tryParse(json['checkOutTime'])
          : null,
      checkOutLat: (json['checkOutLat'] as num?)?.toDouble(),
      checkOutLng: (json['checkOutLng'] as num?)?.toDouble(),
      checkOutAddress: json['checkOutAddress'],
      workingHours: (json['workingHours'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PRESENT',
      notes: json['notes'],
      workerName: user?['name'],
      department: user?['department'],
      designation: user?['designation'],
      isLocked: json['isLocked'] ?? false,
    );
  }
}
