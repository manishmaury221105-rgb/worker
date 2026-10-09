import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfPayslipGenerator {
  /// Generate PDF document bytes for a payslip
  static Future<Uint8List> generatePayslipPdf({
    required String workerName,
    required String phone,
    String? designation,
    String? department,
    required String monthName,
    required int year,
    required double dailyWage,
    required double presentDays,
    required double totalSalary,
    double bonus = 0.0,
    double deductions = 0.0,
    String? remarks,
    String status = 'PAID (DONE)',
    DateTime? paymentDate,
  }) async {
    final pdf = pw.Document();

    // Load font with Hindi / Devanagari support
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

    final daysStr = presentDays.toStringAsFixed(presentDays.truncateToDouble() == presentDays ? 0 : 1);
    final wageStr = dailyWage.toStringAsFixed(0);
    final totalStr = totalSalary.toStringAsFixed(0);
    final generatedOn = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue900, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Top Header with Logo and Brand
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 72,
                        height: 72,
                        margin: const pw.EdgeInsets.only(right: 16),
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
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'SHREE LAXMINARAYAN ALUMINIUM WORKS',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.amber800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'मजबूती भी, सुंदरता भी – बस हमारे साथ !',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'पता: घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            'संपर्क: 9695718820 | 99670 80639 | 98928 26110',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 8),

                // Title Banner
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'वेतन पर्ची / SALARY PAYSLIP',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'महीना / Period: $monthName $year',
                        style: pw.TextStyle(
                          color: PdfColors.amber300,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 14),

                // Worker Details Card
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPdfInfoField('कर्मचारी का नाम / Worker Name', workerName, isBold: true),
                          _buildPdfInfoField('मोबाइल नंबर / Mobile No.', phone),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPdfInfoField('पद / Designation', designation ?? 'Aluminium Fabricator'),
                          _buildPdfInfoField('विभाग / Department', department ?? 'Fabrication'),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 14),

                // Table Breakdown
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableHeader('विवरण / Description'),
                        _buildTableHeader('मात्रा / Rate / Days', alignRight: true),
                        _buildTableHeader('रकम / Amount (₹)', alignRight: true),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableCell('दैनिक वेतन दर (Daily Wage Rate)'),
                        _buildTableCell('₹$wageStr / day', alignRight: true),
                        _buildTableCell('₹$wageStr', alignRight: true),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableCell('कुल उपस्थित दिन (Total Present Days)'),
                        _buildTableCell('$daysStr दिन', alignRight: true),
                        _buildTableCell('₹${(dailyWage * presentDays).toStringAsFixed(0)}', alignRight: true),
                      ],
                    ),
                    if (bonus > 0)
                      pw.TableRow(
                        children: [
                          _buildTableCell('बोनस / अतिरिक्त भत्ता (Bonus / Extra)'),
                          _buildTableCell('-', alignRight: true),
                          _buildTableCell('+₹${bonus.toStringAsFixed(0)}', alignRight: true),
                        ],
                      ),
                    if (deductions > 0)
                      pw.TableRow(
                        children: [
                          _buildTableCell('कटौती / अग्रिम भुगतान (Deductions / Advance)'),
                          _buildTableCell('-', alignRight: true),
                          _buildTableCell('-₹${deductions.toStringAsFixed(0)}', alignRight: true),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // Net Salary Grand Total Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.green700, width: 1.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'कुल देय वेतन (TOTAL NET SALARY)',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green900,
                            ),
                          ),
                          pw.Text(
                            'Calculation: ₹$wageStr × $daysStr दिन',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        '₹$totalStr',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Status and Remarks
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('स्थिति / Status: ', style: const pw.TextStyle(fontSize: 10)),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: status.toUpperCase().contains('PAID') || status.toUpperCase().contains('DONE')
                                ? PdfColors.green100
                                : PdfColors.amber100,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.all(
                              color: status.toUpperCase().contains('PAID') || status.toUpperCase().contains('DONE')
                                  ? PdfColors.green700
                                  : PdfColors.amber700,
                            ),
                          ),
                          child: pw.Text(
                            status,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: status.toUpperCase().contains('PAID') || status.toUpperCase().contains('DONE')
                                  ? PdfColors.green900
                                  : PdfColors.amber900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (paymentDate != null)
                      pw.Text(
                        'भुगतान तिथि: ${DateFormat('dd MMM yyyy').format(paymentDate)}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                  ],
                ),

                if (remarks != null && remarks.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'टिप्पणी / Remarks: $remarks',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                ],

                pw.Spacer(),

                // Sign-off & Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Generated On: $generatedOn',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          'श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स - आधिकारिक वेतन पर्ची',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 120,
                          height: 1,
                          color: PdfColors.grey700,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'अधिकृत हस्ताक्षर (Authorized Signatory)',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfInfoField(String label, String value, {bool isBold = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  /// Print or Preview PDF directly
  static Future<void> printPayslipPdf({
    required String workerName,
    required String phone,
    String? designation,
    String? department,
    required String monthName,
    required int year,
    required double dailyWage,
    required double presentDays,
    required double totalSalary,
    double bonus = 0.0,
    double deductions = 0.0,
    String? remarks,
    String status = 'PAID (DONE)',
    DateTime? paymentDate,
  }) async {
    final pdfBytes = await generatePayslipPdf(
      workerName: workerName,
      phone: phone,
      designation: designation,
      department: department,
      monthName: monthName,
      year: year,
      dailyWage: dailyWage,
      presentDays: presentDays,
      totalSalary: totalSalary,
      bonus: bonus,
      deductions: deductions,
      remarks: remarks,
      status: status,
      paymentDate: paymentDate,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Salary_Payslip_${workerName.replaceAll(" ", "_")}_${monthName}_$year.pdf',
    );
  }

  /// Share PDF file via WhatsApp / System Share Sheet
  static Future<void> sharePayslipPdf({
    required String workerName,
    required String phone,
    String? designation,
    String? department,
    required String monthName,
    required int year,
    required double dailyWage,
    required double presentDays,
    required double totalSalary,
    double bonus = 0.0,
    double deductions = 0.0,
    String? remarks,
    String status = 'PAID (DONE)',
    DateTime? paymentDate,
  }) async {
    final pdfBytes = await generatePayslipPdf(
      workerName: workerName,
      phone: phone,
      designation: designation,
      department: department,
      monthName: monthName,
      year: year,
      dailyWage: dailyWage,
      presentDays: presentDays,
      totalSalary: totalSalary,
      bonus: bonus,
      deductions: deductions,
      remarks: remarks,
      status: status,
      paymentDate: paymentDate,
    );

    final filename = 'Salary_Payslip_${workerName.replaceAll(" ", "_")}_${monthName}_$year.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }
}
