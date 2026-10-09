import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/salary_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salary_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';
import '../../core/utils/pdf_payslip_generator.dart';

class WorkerSalaryScreen extends StatefulWidget {
  const WorkerSalaryScreen({super.key});

  @override
  State<WorkerSalaryScreen> createState() => _WorkerSalaryScreenState();
}

class _WorkerSalaryScreenState extends State<WorkerSalaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final salProv = Provider.of<SalaryProvider>(context, listen: false);
      final attProv = Provider.of<AttendanceProvider>(context, listen: false);
      salProv.fetchMySalaryRecords();
      attProv.fetchMyHistory();
    });
  }

  void _showPayslipDetails(SalaryRecordModel slip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payslip: Month ${slip.month}/${slip.year}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  StatusBadge(status: slip.status),
                ],
              ),
              const Divider(height: 28),
              _DetailRow(label: 'Daily Base Salary', value: '₹${slip.baseSalary.toStringAsFixed(0)}/day'),
              _DetailRow(
                label: 'Present Days (उपस्थित दिन)',
                value: '${slip.presentDays} Days (${slip.totalWorkingHours} hrs)',
                color: AppColors.success,
                isBold: true,
              ),
              _DetailRow(label: 'Allowances & Incentives', value: '+₹${slip.allowance.toStringAsFixed(0)}', color: AppColors.success),
              _DetailRow(label: 'Deductions', value: '-₹${slip.deductions.toStringAsFixed(0)}', color: AppColors.error),
              const Divider(height: 20),
              _DetailRow(
                label: 'Net Payable Salary',
                value: '₹${slip.netSalary.toStringAsFixed(0)}',
                isBold: true,
                color: AppColors.primary,
                fontSize: 17,
              ),
              if (slip.paymentDate != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Payment Method',
                  value: '${slip.paymentMethod ?? "Bank Transfer"} on ${DateFormat('dd MMM yyyy').format(slip.paymentDate!)}',
                ),
              ],
              const SizedBox(height: 20),
              CustomButton(
                text: '📄 Download / Share PDF (पीडीएफ डाउनलोड/शेयर)',
                icon: Icons.picture_as_pdf_rounded,
                variant: ButtonVariant.primary,
                height: 44,
                onPressed: () {
                  final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                  PdfPayslipGenerator.sharePayslipPdf(
                    workerName: slip.workerName ?? user?.name ?? 'Worker',
                    phone: slip.workerPhone ?? user?.phone ?? '',
                    designation: slip.designation ?? user?.designation,
                    department: slip.department ?? user?.department,
                    monthName: DateFormat('MMMM').format(DateTime(slip.year, slip.month)),
                    year: slip.year,
                    dailyWage: slip.baseSalary,
                    presentDays: slip.presentDays.toDouble(),
                    totalSalary: slip.netSalary,
                    bonus: slip.allowance,
                    deductions: slip.deductions,
                    remarks: slip.notes,
                    status: slip.status,
                    paymentDate: slip.paymentDate,
                  );
                },
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: '🖨️ Print / Preview PDF (प्रिंट करें)',
                icon: Icons.print_rounded,
                variant: ButtonVariant.outline,
                height: 44,
                onPressed: () {
                  final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                  PdfPayslipGenerator.printPayslipPdf(
                    workerName: slip.workerName ?? user?.name ?? 'Worker',
                    phone: slip.workerPhone ?? user?.phone ?? '',
                    designation: slip.designation ?? user?.designation,
                    department: slip.department ?? user?.department,
                    monthName: DateFormat('MMMM').format(DateTime(slip.year, slip.month)),
                    year: slip.year,
                    dailyWage: slip.baseSalary,
                    presentDays: slip.presentDays.toDouble(),
                    totalSalary: slip.netSalary,
                    bonus: slip.allowance,
                    deductions: slip.deductions,
                    remarks: slip.notes,
                    status: slip.status,
                    paymentDate: slip.paymentDate,
                  );
                },
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Close',
                variant: ButtonVariant.outline,
                height: 42,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salProv = Provider.of<SalaryProvider>(context);
    final attProv = Provider.of<AttendanceProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authProv.currentUser;

    // Calculate pending & paid sums
    final totalPending = salProv.mySalaryRecords
        .where((s) => s.status == 'PENDING')
        .fold(0.0, (sum, s) => sum + s.netSalary);

    final totalPaid = salProv.mySalaryRecords
        .where((s) => s.status == 'PAID')
        .fold(0.0, (sum, s) => sum + s.netSalary);

    // Present days from current attendance history (30 days)
    final presentDaysCount = attProv.history
        .where((a) => a.status == 'PRESENT' || a.status == 'LATE')
        .length;
    final halfDaysCount = attProv.history
        .where((a) => a.status == 'HALF_DAY')
        .length;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          salProv.fetchMySalaryRecords(),
          attProv.fetchMyHistory(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Pending Payment Highlight Card (बकाया भुगतान)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: totalPending > 0
                      ? [const Color(0xFFEA580C), const Color(0xFFC2410C)] // Amber-Orange
                      : [const Color(0xFF0D9488), const Color(0xFF059669)], // Teal-Emerald
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (totalPending > 0 ? const Color(0xFFEA580C) : const Color(0xFF059669)).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.pending_actions_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Pending Payment (बकाया वेतन)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          totalPending > 0 ? 'DUE' : 'CLEAR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '₹${totalPending.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalPending > 0
                        ? 'Total unpaid payment pending from Admin'
                        : 'All generated payslips have been paid',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Three Metric Cards: Present Days, Total Paid, Base Rate
            Row(
              children: [
                // Present Days Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.event_available_rounded, color: AppColors.success, size: 16),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Present Days',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$presentDaysCount Days',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        if (halfDaysCount > 0)
                          Text(
                            '+ $halfDaysCount Half Days',
                            style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Total Paid Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Total Paid',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalPaid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Paid by Admin',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Daily Base Salary
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.speed_rounded, color: Colors.purple, size: 16),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Daily Rate',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${user?.monthlySalary.toStringAsFixed(0) ?? "800"}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const Text(
                          'Per day',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (salProv.errorMessage != null) ...[
              ErrorBanner(message: salProv.errorMessage!),
              const SizedBox(height: 10),
            ],

            // 3. Payslips Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Salary History (वेतन रिकॉर्ड)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${salProv.mySalaryRecords.length} Payslips',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (salProv.isLoading && salProv.mySalaryRecords.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (salProv.mySalaryRecords.isEmpty)
              EmptyStateView(
                icon: Icons.receipt_long_rounded,
                title: 'No payslips generated yet',
                subtitle: 'Monthly payslips and payments will appear here once processed by Admin',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: salProv.mySalaryRecords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final slip = salProv.mySalaryRecords[index];
                  final isPending = slip.status == 'PENDING';

                  return InkWell(
                    onTap: () => _showPayslipDetails(slip),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPending
                              ? Colors.orange.withOpacity(0.4)
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: isPending ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isPending ? Colors.orange : AppColors.success).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPending ? Icons.pending_rounded : Icons.check_circle_rounded,
                              color: isPending ? Colors.orange : AppColors.success,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Month ${slip.month}/${slip.year}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${slip.presentDays} Days Present',
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    if (isPending) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'DUE',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Net Salary: ₹${slip.netSalary.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusBadge(status: slip.status),
                              const SizedBox(height: 6),
                              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  final double fontSize;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
