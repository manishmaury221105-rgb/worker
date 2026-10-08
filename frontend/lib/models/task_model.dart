class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedToId;
  final String createdById;
  final String status; // 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
  final String priority; // 'LOW', 'MEDIUM', 'HIGH', 'URGENT'
  final DateTime? dueDate;
  final String? location;
  final String? completionNotes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? workerName;
  final String? workerPhone;
  final String? creatorName;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToId,
    required this.createdById,
    required this.status,
    required this.priority,
    this.dueDate,
    this.location,
    this.completionNotes,
    this.completedAt,
    required this.createdAt,
    this.workerName,
    this.workerPhone,
    this.creatorName,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isInProgress => status == 'IN_PROGRESS';

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'] as Map<String, dynamic>?;
    final createdBy = json['createdBy'] as Map<String, dynamic>?;

    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedToId: json['assignedToId'] ?? '',
      createdById: json['createdById'] ?? '',
      status: json['status'] ?? 'PENDING',
      priority: json['priority'] ?? 'MEDIUM',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      location: json['location'],
      completionNotes: json['completionNotes'],
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      workerName: assignedTo?['name'],
      workerPhone: assignedTo?['phone'],
      creatorName: createdBy?['name'],
    );
  }
}
