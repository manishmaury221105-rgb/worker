import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<bool> sendSalaryPayslip({
    required String phone,
    required String workerName,
    required String monthName,
    required int year,
    required double dailyWage,
    required double presentDays,
    required double totalSalary,
    String? remarks,
  }) async {
    // Sanitize phone number (remove all non-digit characters)
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final daysStr = presentDays.toStringAsFixed(presentDays.truncateToDouble() == presentDays ? 0 : 1);
    final wageStr = dailyWage.toStringAsFixed(0);
    final totalStr = totalSalary.toStringAsFixed(0);

    final message = '''
📄 *वेतन पर्ची / SALARY PAYSLIP* 📄
━━━━━━━━━━━━━━━━━━━━
👤 *Worker / कर्मचारी:* $workerName
📅 *Month / महीना:* $monthName $year
💵 *दैनिक वेतन (Daily Wage):* ₹$wageStr / day
⏱️ *उपस्थित दिन (Present Days):* $daysStr दिन
━━━━━━━━━━━━━━━━━━━━
💰 *TOTAL SALARY / कुल वेतन:* *₹$totalStr*
━━━━━━━━━━━━━━━━━━━━
🏢 *श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स*
📍 *पता:* घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर
📞 *संपर्क:* 9695718820 / 9892826110
${remarks != null && remarks.trim().isNotEmpty ? '📝 *Remarks:* $remarks\n' : ''}✅ *Status:* Verified & Approved
━━━━━━━━━━━━━━━━━━━━
_मजबूती भी, सुंदरता भी – बस हमारे साथ !_
''';

    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      // Fallback url launch
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      return true;
    }
    return false;
  }
}
