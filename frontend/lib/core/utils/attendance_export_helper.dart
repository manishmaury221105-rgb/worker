import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';

class AttendanceExportHelper {
  /// Export & Download Admin Daily Attendance Report (CSV)
  static Future<String> exportAdminDailyReport({
    required DateTime date,
    required List<UserModel> workers,
    required List<AttendanceModel> attendances,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dateDisplay = DateFormat('dd MMMM yyyy (EEEE)').format(date);

    // Map worker attendance
    final Map<String, AttendanceModel> attMap = {};
    for (var a in attendances) {
      attMap[a.userId] = a;
    }

    int presentCount = 0;
    int lateCount = 0;
    int halfDayCount = 0;
    int absentCount = 0;

    final List<List<String>> rows = [];
    rows.add(['श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स - WORKER ATTENDANCE REPORT', dateDisplay]);
    rows.add(['Generated On', DateFormat('dd MMM yyyy hh:mm a').format(DateTime.now())]);
    rows.add([]);

    rows.add([
      'S.No',
      'Worker Name',
      'Phone Number',
      'Daily Wage (Rs)',
      'Attendance Status',
      'Check-In Time',
      'Check-Out Time',
      'Total Working Hours',
      'Notes / Remarks'
    ]);

    int index = 1;
    for (var w in workers) {
      final att = attMap[w.id];
      final status = att?.status ?? 'ABSENT';

      if (status == 'PRESENT') presentCount++;
      else if (status == 'LATE') lateCount++;
      else if (status == 'HALF_DAY') halfDayCount++;
      else absentCount++;

      final inTime = att?.checkInTime != null
          ? DateFormat('hh:mm a').format(att!.checkInTime!)
          : '-';
      final outTime = att?.checkOutTime != null
          ? DateFormat('hh:mm a').format(att!.checkOutTime!)
          : '-';
      final hours = att != null && att.workingHours > 0
          ? '${att.workingHours.toStringAsFixed(1)} hrs'
          : (status == 'ABSENT' ? '0 hrs' : '8.0 hrs');

      rows.add([
        '$index',
        w.name,
        w.phone,
        w.monthlySalary.toStringAsFixed(0),
        status,
        inTime,
        outTime,
        hours,
        att?.notes ?? '',
      ]);
      index++;
    }

    rows.add([]);
    rows.add(['SUMMARY SUMMARY']);
    rows.add(['Total Workers', '${workers.length}']);
    rows.add(['Present', '$presentCount']);
    rows.add(['Late', '$lateCount']);
    rows.add(['Half Day', '$halfDayCount']);
    rows.add(['Absent', '$absentCount']);

    final csvContent = _generateCsvString(rows);
    final fileName = 'Attendance_Report_$dateStr.csv';

    return await _saveAndDownloadFile(fileName, csvContent);
  }

  /// Export & Download Worker Personal Attendance History (CSV)
  static Future<String> exportWorkerHistory({
    required String workerName,
    required String phone,
    required List<AttendanceModel> history,
  }) async {
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final List<List<String>> rows = [];
    rows.add(['PERSONAL ATTENDANCE REPORT', workerName]);
    rows.add(['Phone', phone]);
    rows.add(['Generated On', DateFormat('dd MMM yyyy hh:mm a').format(DateTime.now())]);
    rows.add(['Total Records', '${history.length}']);
    rows.add([]);

    rows.add([
      'Date',
      'Day',
      'Status',
      'Check-In Time',
      'Check-Out Time',
      'Working Hours',
      'Remarks'
    ]);

    for (var att in history) {
      final inTime = att.checkInTime != null
          ? DateFormat('hh:mm a').format(att.checkInTime!)
          : '-';
      final outTime = att.checkOutTime != null
          ? DateFormat('hh:mm a').format(att.checkOutTime!)
          : '-';

      rows.add([
        DateFormat('dd-MM-yyyy').format(att.date),
        DateFormat('EEEE').format(att.date),
        att.status,
        inTime,
        outTime,
        '${att.workingHours.toStringAsFixed(1)} hrs',
        att.notes ?? '',
      ]);
    }

    final csvContent = _generateCsvString(rows);
    final fileName = 'My_Attendance_${workerName.replaceAll(" ", "_")}_$nowStr.csv';

    return await _saveAndDownloadFile(fileName, csvContent);
  }

  /// Convert 2D list to CSV format with escaping
  static String _generateCsvString(List<List<String>> rows) {
    return rows.map((row) {
      return row.map((field) {
        if (field.contains(',') || field.contains('"') || field.contains('\n')) {
          return '"${field.replaceAll('"', '""')}"';
        }
        return field;
      }).join(',');
    }).join('\r\n');
  }

  /// Cross-platform download trigger
  static Future<String> _saveAndDownloadFile(String fileName, String content) async {
    if (kIsWeb) {
      final uri = Uri.dataFromString(
        content,
        mimeType: 'text/csv',
        encoding: utf8,
      );
      await launchUrl(uri);
      return 'Downloaded in browser: $fileName';
    } else {
      try {
        final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(content, encoding: utf8);
        return 'File saved to: ${file.path}';
      } catch (e) {
        // Fallback data URI
        final uri = Uri.dataFromString(content, mimeType: 'text/csv', encoding: utf8);
        await launchUrl(uri);
        return 'Exported $fileName';
      }
    }
  }

  /// Share text summary of Attendance to WhatsApp
  static Future<void> shareAttendanceToWhatsApp({
    required String phone,
    required String title,
    required String summaryText,
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';

    final message = '''
📊 *$title* 📊
━━━━━━━━━━━━━━━━━━━━
$summaryText
━━━━━━━━━━━━━━━━━━━━
🏢 *श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स*
📍 _घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर_
''';

    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
