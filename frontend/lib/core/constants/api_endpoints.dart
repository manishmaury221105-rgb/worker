import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      String clean = url.trim();
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'http://$clean';
      }
      while (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      if (!clean.endsWith('/api')) {
        clean = '$clean/api';
      }
      _customBaseUrl = clean;
    } else {
      _customBaseUrl = null;
    }
  }

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5050/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'https://map-furniture-ideal-fall.trycloudflare.com/api';
      default:
        return 'http://localhost:5050/api';
    }
  }

  // Base URL - Custom if configured, otherwise platform default
  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // Workers
  static const String workers = '/workers';
  static const String departments = '/workers/departments';

  // Attendance
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String selfMarkAttendance = '/attendance/self-mark';
  static const String todayAttendance = '/attendance/today';
  static const String myAttendanceHistory = '/attendance/my-history';
  static const String allAttendance = '/attendance/all';
  static const String attendanceSummary = '/attendance/summary';
  static const String manualAttendance = '/attendance/manual';
  static const String attendanceLockStatus = '/attendance/lock-status';
  static const String attendanceToggleLock = '/attendance/toggle-lock';
  static const String workerMonthlyAttendance = '/attendance/worker-monthly';

  // Tasks
  static const String tasks = '/tasks';
  static const String myTasks = '/tasks/my-tasks';

  // Leaves
  static const String applyLeave = '/leaves/apply';
  static const String myLeaves = '/leaves/my-leaves';
  static const String allLeaves = '/leaves/all';

  // Salary & Advance
  static const String mySalaryRecords = '/salary/my-records';
  static const String allSalaryRecords = '/salary/all-records';
  static const String generatePayslip = '/salary/generate-payslip';
  static const String requestAdvance = '/salary/advance/request';
  static const String myAdvances = '/salary/advance/my';
  static const String allAdvances = '/salary/advance/all';

  // Expenses
  static const String submitExpense = '/expenses/submit';
  static const String myExpenses = '/expenses/my';
  static const String allExpenses = '/expenses/all';

  // Notifications
  static const String myNotifications = '/notifications/my';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String broadcastNotification = '/notifications/broadcast';

  // Reports
  static const String dashboardReport = '/reports/dashboard';
}
