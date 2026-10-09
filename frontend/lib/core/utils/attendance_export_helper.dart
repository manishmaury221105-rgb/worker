import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';

class AttendanceExportHelper {
  /// Generate & Download / Print Admin Daily Attendance PDF
  static Future<void> exportAdminDailyReportPdf({
    required DateTime date,
    required List<UserModel> workers,
    required List<AttendanceModel> attendances,
  }) async {
    final pdf = pw.Document();
    final dateDisplay = DateFormat('dd MMMM yyyy (EEEE)').format(date);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Load Devanagari font
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      regularFont = await PdfGoogleFonts.notoSansDevanagariRegular();
      boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    } catch (_) {
      try {
        regularFont = await PdfGoogleFonts.robotoRegular();
        boldFont = await PdfGoogleFonts.robotoBold();
      } catch (_) {
        regularFont = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
      }
    }

    // Load company logo image
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Map worker attendance
    final Map<String, AttendanceModel> attMap = {};
    for (var a in attendances) {
      attMap[a.userId] = a;
    }

    int presentCount = 0;
    int lateCount = 0;
    int halfDayCount = 0;
    int absentCount = 0;

    for (var w in workers) {
      final att = attMap[w.id];
      final status = att?.status ?? 'ABSENT';
      if (status == 'PRESENT') presentCount++;
      else if (status == 'LATE') lateCount++;
      else if (status == 'HALF_DAY') halfDayCount++;
      else absentCount++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 56,
                      height: 56,
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.ClipOval(
                        child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'दैनिक उपस्थिति रिपोर्ट / DAILY ATTENDANCE REPORT',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber800,
                          ),
                        ),
                        pw.Text(
                          'तारीख (Date): $dateDisplay',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'संपर्क: 9695718820',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        '99670 80639 / 98928 26110',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1.2, color: PdfColors.blue900),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Summary KPI Cards
            pw.Row(
              children: [
                _buildKpiPdfCard('Total Workers', '${workers.length}', PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildKpiPdfCard('Present', '$presentCount', PdfColors.green800),
                pw.SizedBox(width: 8),
                _buildKpiPdfCard('Late', '$lateCount', PdfColors.orange800),
                pw.SizedBox(width: 8),
                _buildKpiPdfCard('Half Day', '$halfDayCount', PdfColors.purple800),
                pw.SizedBox(width: 8),
                _buildKpiPdfCard('Absent', '$absentCount', PdfColors.red800),
              ],
            ),
            pw.SizedBox(height: 12),

            // Attendance Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _buildPdfTableHeader('#', width: 25, isWhite: true),
                    _buildPdfTableHeader('Worker Name', isWhite: true),
                    _buildPdfTableHeader('Mobile No.', isWhite: true),
                    _buildPdfTableHeader('Wage Rate', alignRight: true, isWhite: true),
                    _buildPdfTableHeader('In Time', isWhite: true),
                    _buildPdfTableHeader('Out Time', isWhite: true),
                    _buildPdfTableHeader('Hours', isWhite: true),
                    _buildPdfTableHeader('Status', isWhite: true),
                  ],
                ),
                ...workers.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final w = entry.value;
                  final att = attMap[w.id];
                  final status = att?.status ?? 'ABSENT';

                  final inTime = att?.checkInTime != null
                      ? DateFormat('hh:mm a').format(att!.checkInTime!)
                      : '-';
                  final outTime = att?.checkOutTime != null
                      ? DateFormat('hh:mm a').format(att!.checkOutTime!)
                      : '-';
                  final hours = att != null && att.workingHours > 0
                      ? '${att.workingHours.toStringAsFixed(1)}h'
                      : (status == 'ABSENT' ? '0h' : '8.0h');

                  final isEven = entry.key % 2 == 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey100),
                    children: [
                      _buildPdfTableCell('$index', alignCenter: true),
                      _buildPdfTableCell(w.name, isBold: true),
                      _buildPdfTableCell(w.phone),
                      _buildPdfTableCell('₹${w.monthlySalary.toStringAsFixed(0)}', alignRight: true),
                      _buildPdfTableCell(inTime, alignCenter: true),
                      _buildPdfTableCell(outTime, alignCenter: true),
                      _buildPdfTableCell(hours, alignCenter: true),
                      _buildPdfStatusCell(status),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated On: ${DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स - मड़ियाहूँ, जौनपुर',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Attendance_Report_$dateStr.pdf',
    );
  }

  /// Generate & Download / Print Worker Personal Attendance PDF
  static Future<void> exportWorkerHistoryPdf({
    required String workerName,
    required String phone,
    required List<AttendanceModel> history,
  }) async {
    final pdf = pw.Document();
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Load Devanagari font
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      regularFont = await PdfGoogleFonts.notoSansDevanagariRegular();
      boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    } catch (_) {
      try {
        regularFont = await PdfGoogleFonts.robotoRegular();
        boldFont = await PdfGoogleFonts.robotoBold();
      } catch (_) {
        regularFont = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
      }
    }

    // Load logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    int presentDays = 0;
    int lateDays = 0;
    int halfDays = 0;
    int absentDays = 0;

    for (var a in history) {
      if (a.status == 'PRESENT') presentDays++;
      else if (a.status == 'LATE') lateDays++;
      else if (a.status == 'HALF_DAY') halfDays++;
      else absentDays++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 54,
                      height: 54,
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.ClipOval(
                        child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'कर्मचारी उपस्थिति रिकॉर्ड / PERSONAL ATTENDANCE CARD',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber800,
                          ),
                        ),
                        pw.Text(
                          'Worker: $workerName ($phone)',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1.2, color: PdfColors.blue900),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Stats Row
            pw.Row(
              children: [
                _buildKpiPdfCard('Total Records', '${history.length}', PdfColors.blue900),
                pw.SizedBox(width: 8),
                _buildKpiPdfCard('Present', '$presentDays', PdfColors.green800),
                pw.SizedBox(width: 8),
                _buildKpiPdfCard('Late', '$lateDays', PdfColors.orange800),
                pw.SizedBox(width: 8),
                _buildKpiPdfCard('Half Day', '$halfDays', PdfColors.purple800),
                pw.SizedBox(width: 8),
                _buildKpiPdfCard('Absent', '$absentDays', PdfColors.red800),
              ],
            ),
            pw.SizedBox(height: 12),

            // History Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _buildPdfTableHeader('Date (तारीख)', isWhite: true),
                    _buildPdfTableHeader('Day (दिन)', isWhite: true),
                    _buildPdfTableHeader('In Time', isWhite: true),
                    _buildPdfTableHeader('Out Time', isWhite: true),
                    _buildPdfTableHeader('Hours', isWhite: true),
                    _buildPdfTableHeader('Status', isWhite: true),
                    _buildPdfTableHeader('Remarks', isWhite: true),
                  ],
                ),
                ...history.asMap().entries.map((entry) {
                  final att = entry.value;
                  final inTime = att.checkInTime != null
                      ? DateFormat('hh:mm a').format(att.checkInTime!)
                      : '-';
                  final outTime = att.checkOutTime != null
                      ? DateFormat('hh:mm a').format(att.checkOutTime!)
                      : '-';
                  final isEven = entry.key % 2 == 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey100),
                    children: [
                      _buildPdfTableCell(DateFormat('dd-MM-yyyy').format(att.date), isBold: true),
                      _buildPdfTableCell(DateFormat('EEEE').format(att.date)),
                      _buildPdfTableCell(inTime, alignCenter: true),
                      _buildPdfTableCell(outTime, alignCenter: true),
                      _buildPdfTableCell('${att.workingHours.toStringAsFixed(1)}h', alignCenter: true),
                      _buildPdfStatusCell(att.status),
                      _buildPdfTableCell(att.notes ?? '-'),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated On: ${DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स - मड़ियाहूँ, जौनपुर',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Attendance_${workerName.replaceAll(" ", "_")}_$nowStr.pdf',
    );
  }

  /// Share CSV via System Share Sheet / WhatsApp
  static Future<void> shareAdminDailyReportCsv({
    required DateTime date,
    required List<UserModel> workers,
    required List<AttendanceModel> attendances,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dateDisplay = DateFormat('dd MMMM yyyy (EEEE)').format(date);

    final Map<String, AttendanceModel> attMap = {};
    for (var a in attendances) {
      attMap[a.userId] = a;
    }

    final List<List<String>> rows = [];
    rows.add(['श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स - ATTENDANCE REPORT', dateDisplay]);
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
      'Notes'
    ]);

    int index = 1;
    for (var w in workers) {
      final att = attMap[w.id];
      final status = att?.status ?? 'ABSENT';
      final inTime = att?.checkInTime != null ? DateFormat('hh:mm a').format(att!.checkInTime!) : '-';
      final outTime = att?.checkOutTime != null ? DateFormat('hh:mm a').format(att!.checkOutTime!) : '-';
      final hours = att != null && att.workingHours > 0 ? '${att.workingHours.toStringAsFixed(1)} hrs' : (status == 'ABSENT' ? '0 hrs' : '8.0 hrs');

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

    final csvContent = _generateCsvString(rows);
    final fileName = 'Attendance_Report_$dateStr.csv';
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    if (kIsWeb) {
      final uri = Uri.dataFromString(csvContent, mimeType: 'text/csv', encoding: utf8);
      await launchUrl(uri);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }

  /// Share Worker History CSV
  static Future<void> shareWorkerHistoryCsv({
    required String workerName,
    required String phone,
    required List<AttendanceModel> history,
  }) async {
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final List<List<String>> rows = [];
    rows.add(['PERSONAL ATTENDANCE REPORT', workerName]);
    rows.add(['Phone', phone]);
    rows.add(['Generated On', DateFormat('dd MMM yyyy hh:mm a').format(DateTime.now())]);
    rows.add([]);

    rows.add(['Date', 'Day', 'Status', 'Check-In Time', 'Check-Out Time', 'Working Hours', 'Remarks']);

    for (var att in history) {
      final inTime = att.checkInTime != null ? DateFormat('hh:mm a').format(att.checkInTime!) : '-';
      final outTime = att.checkOutTime != null ? DateFormat('hh:mm a').format(att.checkOutTime!) : '-';

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
    final fileName = 'Attendance_${workerName.replaceAll(" ", "_")}_$nowStr.csv';
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    if (kIsWeb) {
      final uri = Uri.dataFromString(csvContent, mimeType: 'text/csv', encoding: utf8);
      await launchUrl(uri);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }

  static pw.Widget _buildKpiPdfCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 8, color: color, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, color: color, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTableHeader(String text, {double? width, bool isWhite = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: isWhite ? PdfColors.white : PdfColors.blue900,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTableCell(String text, {bool isBold = false, bool alignCenter = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: alignCenter ? pw.TextAlign.center : (alignRight ? pw.TextAlign.right : pw.TextAlign.left),
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfStatusCell(String status) {
    PdfColor bgColor = PdfColors.grey200;
    PdfColor textColor = PdfColors.black;

    if (status == 'PRESENT') {
      bgColor = PdfColors.green100;
      textColor = PdfColors.green900;
    } else if (status == 'LATE') {
      bgColor = PdfColors.orange100;
      textColor = PdfColors.orange900;
    } else if (status == 'HALF_DAY') {
      bgColor = PdfColors.purple100;
      textColor = PdfColors.purple900;
    } else if (status == 'ABSENT') {
      bgColor = PdfColors.red100;
      textColor = PdfColors.red900;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          status,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

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
}
