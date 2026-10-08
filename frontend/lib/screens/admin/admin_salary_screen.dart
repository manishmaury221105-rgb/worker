import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/salary_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/salary_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_badge.dart';
import '../../core/utils/whatsapp_helper.dart';

class AdminSalaryScreen extends StatefulWidget {
  const AdminSalaryScreen({super.key});

  @override
  State<AdminSalaryScreen> createState() => _AdminSalaryScreenState();
}

class _AdminSalaryScreenState extends State<AdminSalaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final salProv = Provider.of<SalaryProvider>(context, listen: false);
      salProv.fetchAllSalaryRecords();
      Provider.of<AdminProvider>(context, listen: false).fetchWorkers();
    });
  }

  void _showGeneratePayslipSheet() {
    final formKey = GlobalKey<FormState>();
    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    String? selectedWorkerId = adminProv.workers.isNotEmpty ? adminProv.workers.first.id : null;
    int month = DateTime.now().month;
    int year = DateTime.now().year;
    final daysController = TextEditingController(text: '30');
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final salProv = Provider.of<SalaryProvider>(context);

          final currentWorker = adminProv.workers.firstWhere(
            (w) => w.id == selectedWorkerId,
            orElse: () => adminProv.workers.first,
          );
          final dailyWage = currentWorker.monthlySalary;
          final days = double.tryParse(daysController.text.trim()) ?? 0;
          final totalSalary = dailyWage * days;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Generate Worker Payslip',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedWorkerId,
                      decoration: const InputDecoration(labelText: 'Worker'),
                      items: adminProv.workers.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text('${w.name} (₹${w.monthlySalary.toStringAsFixed(0)}/day)'),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedWorkerId = v),
                      validator: (v) => v == null ? 'Select a worker' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: month,
                            decoration: const InputDecoration(labelText: 'Month'),
                            items: List.generate(12, (i) => i + 1).map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(DateFormat('MMMM').format(DateTime(2026, m))),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => month = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: year,
                            decoration: const InputDecoration(labelText: 'Year'),
                            items: [2025, 2026, 2027].map((y) {
                              return DropdownMenuItem(value: y, child: Text('$y'));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => year = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Present Days Input
                    CustomTextField(
                      label: 'Present Days (उपस्थित दिन)',
                      hint: 'e.g. 26 or 30',
                      controller: daysController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.calendar_today_rounded,
                      onChanged: (_) => setModalState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter present days';
                        if (double.tryParse(v) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Live Multiplied Calculation Preview Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withOpacity(0.25)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'दैनिक वेतन (Daily Wage):',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              Text(
                                '₹${dailyWage.toStringAsFixed(0)} / day',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'उपस्थित दिन (Present Days):',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              Text(
                                '× ${days.toStringAsFixed(days.truncateToDouble() == days ? 0 : 1)} days',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'कुल वेतन (Total Salary):',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${totalSalary.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Payroll Remarks (Optional)',
                      hint: 'e.g. Monthly salary calculation...',
                      controller: notesController,
                    ),
                    const SizedBox(height: 20),

                    CustomButton(
                      text: 'Calculate & Generate (₹${totalSalary.toStringAsFixed(0)})',
                      isLoading: salProv.isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate() || selectedWorkerId == null) return;
                        final success = await salProv.generatePayslip(
                          userId: selectedWorkerId!,
                          month: month,
                          year: year,
                          presentDays: days,
                          bonus: 0,
                          deductions: 0,
                          notes: notesController.text.trim(),
                        );
                        if (success) {
                          Navigator.of(ctx).pop();
                          // Send / Open payslip on worker's WhatsApp
                          await WhatsAppHelper.sendSalaryPayslip(
                            phone: currentWorker.phone,
                            workerName: currentWorker.name,
                            monthName: DateFormat('MMMM').format(DateTime(year, month)),
                            year: year,
                            dailyWage: dailyWage,
                            presentDays: days,
                            totalSalary: totalSalary,
                            remarks: notesController.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Payslip generated & WhatsApp opened for ${currentWorker.name}!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salProv = Provider.of<SalaryProvider>(context);
    final adminProv = Provider.of<AdminProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => salProv.fetchAllSalaryRecords(),
        child: salProv.isLoading && salProv.allSalaryRecords.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : salProv.allSalaryRecords.isEmpty
                ? EmptyStateView(
                    icon: Icons.payments_outlined,
                    title: 'No salary records generated',
                    buttonText: 'Generate Payslip',
                    onButtonPressed: _showGeneratePayslipSheet,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: salProv.allSalaryRecords.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'कुल बकाया भुगतान (Total Pending Due)',
                                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${salProv.pendingPayoutCount} Pending',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${salProv.totalPendingPayout.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(color: Colors.white24, height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Generated: ₹${salProv.totalSalaryAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    Text(
                                      'Paid: ₹${salProv.totalPaidPayout.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final slip = salProv.allSalaryRecords[index - 1];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    slip.workerName ?? 'Worker Name',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded, color: AppColors.success, size: 20),
                                  tooltip: 'Send Payslip to Worker WhatsApp',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final worker = adminProv.workers.firstWhere(
                                      (w) => w.id == slip.userId,
                                      orElse: () => adminProv.workers.first,
                                    );
                                    WhatsAppHelper.sendSalaryPayslip(
                                      phone: slip.workerPhone ?? worker.phone,
                                      workerName: slip.workerName ?? worker.name,
                                      monthName: DateFormat('MMMM').format(DateTime(slip.year, slip.month)),
                                      year: slip.year,
                                      dailyWage: slip.baseSalary,
                                      presentDays: slip.presentDays.toDouble(),
                                      totalSalary: slip.netSalary,
                                      remarks: slip.notes,
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                StatusBadge(status: slip.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${slip.designation ?? "Worker"} • ${slip.department ?? ""}  |  Month ${slip.month}/${slip.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Net: ₹${slip.netSalary.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${slip.presentDays} Days Present (${slip.totalWorkingHours} hrs)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            if (!slip.isPaid) ...[
                              const SizedBox(height: 14),
                              CustomButton(
                                text: 'Mark as Paid & Disburse',
                                variant: ButtonVariant.success,
                                height: 40,
                                fontSize: 13,
                                icon: Icons.check_circle_rounded,
                                onPressed: () async {
                                  final success = await salProv.updateSalaryStatus(
                                    recordId: slip.id,
                                    status: 'PAID',
                                    paymentMethod: 'Direct Payment',
                                  );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Salary for ${slip.workerName ?? "Worker"} marked as PAID!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PAID ${slip.paymentDate != null ? "on " + DateFormat("dd MMM yyyy").format(slip.paymentDate!) : ""}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGeneratePayslipSheet,
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Generate Payslip', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
