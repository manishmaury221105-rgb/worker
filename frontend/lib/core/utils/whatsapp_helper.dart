import 'package:flutter/foundation.dart';
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
    if (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
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
📞 *संपर्क:* 9695718820 / 99670 80639 / 98928 26110
${remarks != null && remarks.trim().isNotEmpty ? '📝 *Remarks:* $remarks\n' : ''}✅ *Status:* Verified & Approved
━━━━━━━━━━━━━━━━━━━━
_मजबूती भी, सुंदरता भी – बस हमारे साथ !_
''';

    final encodedMessage = Uri.encodeComponent(message);

    // List of URIs to attempt in order
    final urisToTry = [
      Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMessage'),
      Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage'),
      Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage'),
    ];

    for (final uri in urisToTry) {
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        }
      } catch (e) {
        debugPrint('WhatsApp launch attempt failed: $e');
      }
    }

    // Direct fallback without canLaunchUrl check
    try {
      final directUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');
      await launchUrl(directUri, mode: LaunchMode.externalApplication);
      return true;
    } catch (e) {
      try {
        final directUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');
        await launchUrl(directUri, mode: LaunchMode.platformDefault);
        return true;
      } catch (e2) {
        debugPrint('Direct fallback failed: $e2');
      }
    }

    return false;
  }
}
