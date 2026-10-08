class DashboardStatsModel {
  final int totalWorkers;
  final int activeWorkers;
  final int inactiveWorkers;
  final List<DepartmentStat> departments;
  final int presentToday;
  final int lateToday;
  final int halfDayToday;
  final int absentToday;
  final int onLeaveToday;
  final int attendanceRate;
  final int pendingLeaves;
  final int pendingAdvances;
  final int pendingExpenses;
  final int totalPendingApprovals;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int totalTasks;
  final int taskCompletionRate;
  final int totalWorkingHours;

  DashboardStatsModel({
    required this.totalWorkers,
    required this.activeWorkers,
    required this.inactiveWorkers,
    required this.departments,
    required this.presentToday,
    required this.lateToday,
    required this.halfDayToday,
    required this.absentToday,
    required this.onLeaveToday,
    required this.attendanceRate,
    required this.pendingLeaves,
    required this.pendingAdvances,
    required this.pendingExpenses,
    required this.totalPendingApprovals,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.totalTasks,
    required this.taskCompletionRate,
    required this.totalWorkingHours,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final workers = json['workers'] ?? {};
    final attendance = json['attendanceToday'] ?? {};
    final approvals = json['pendingApprovals'] ?? {};
    final tasks = json['tasks'] ?? {};
    final monthly = json['monthlyMetrics'] ?? {};

    final deptList = (workers['departments'] as List<dynamic>?)
            ?.map((d) => DepartmentStat.fromJson(d))
            .toList() ??
        [];

    return DashboardStatsModel(
      totalWorkers: workers['total'] ?? 0,
      activeWorkers: workers['active'] ?? 0,
      inactiveWorkers: workers['inactive'] ?? 0,
      departments: deptList,
      presentToday: attendance['present'] ?? 0,
      lateToday: attendance['late'] ?? 0,
      halfDayToday: attendance['halfDay'] ?? 0,
      absentToday: attendance['absent'] ?? 0,
      onLeaveToday: attendance['onLeave'] ?? 0,
      attendanceRate: attendance['attendanceRate'] ?? 0,
      pendingLeaves: approvals['leaves'] ?? 0,
      pendingAdvances: approvals['advances'] ?? 0,
      pendingExpenses: approvals['expenses'] ?? 0,
      totalPendingApprovals: approvals['total'] ?? 0,
      pendingTasks: tasks['pending'] ?? 0,
      inProgressTasks: tasks['inProgress'] ?? 0,
      completedTasks: tasks['completed'] ?? 0,
      totalTasks: tasks['total'] ?? 0,
      taskCompletionRate: tasks['completionRate'] ?? 0,
      totalWorkingHours: (monthly['totalWorkingHours'] as num?)?.toInt() ?? 0,
    );
  }
}

class DepartmentStat {
  final String name;
  final int count;

  DepartmentStat({required this.name, required this.count});

  factory DepartmentStat.fromJson(Map<String, dynamic> json) {
    return DepartmentStat(
      name: json['name'] ?? 'General',
      count: json['count'] ?? 0,
    );
  }
}
