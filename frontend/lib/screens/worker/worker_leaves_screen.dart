import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/leave_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';

class WorkerLeavesScreen extends StatefulWidget {
  const WorkerLeavesScreen({super.key});

  @override
  State<WorkerLeavesScreen> createState() => _WorkerLeavesScreenState();
}

class _WorkerLeavesScreenState extends State<WorkerLeavesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).fetchMyLeaves();
    });
  }

  void _showApplyLeaveSheet() {
    final formKey = GlobalKey<FormState>();
    String leaveType = 'CASUAL';
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 2));
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final localeProv = Provider.of<LocaleProvider>(context);
          final leaveProv = Provider.of<LeaveProvider>(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        Text(
                          localeProv.tr('apply_leave'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Leave Type Selector
                    Text(
                      localeProv.tr('leave_type'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _TypePill(
                          label: localeProv.tr('casual_leave'),
                          isSelected: leaveType == 'CASUAL',
                          onTap: () => setModalState(() => leaveType = 'CASUAL'),
                        ),
                        _TypePill(
                          label: localeProv.tr('sick_leave'),
                          isSelected: leaveType == 'SICK',
                          onTap: () => setModalState(() => leaveType = 'SICK'),
                        ),
                        _TypePill(
                          label: localeProv.tr('emergency_leave'),
                          isSelected: leaveType == 'EMERGENCY',
                          onTap: () => setModalState(() => leaveType = 'EMERGENCY'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date Selectors
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) endDate = startDate;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localeProv.tr('start_date'),
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(startDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localeProv.tr('end_date'),
                                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(endDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: localeProv.tr('reason'),
                      hint: 'e.g. Family wedding, urgent medical checkup...',
                      controller: reasonController,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide a reason' : null,
                    ),
                    const SizedBox(height: 20),

                    CustomButton(
                      text: localeProv.tr('submit'),
                      isLoading: leaveProv.isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await leaveProv.applyLeave(
                          leaveType: leaveType,
                          startDate: startDate,
                          endDate: endDate,
                          reason: reasonController.text,
                        );
                        if (success) Navigator.of(ctx).pop();
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
    final localeProv = Provider.of<LocaleProvider>(context);
    final leaveProv = Provider.of<LeaveProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => leaveProv.fetchMyLeaves(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Apply Leave CTA Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localeProv.tr('leave_management'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showApplyLeaveSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(localeProv.tr('apply_leave')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (leaveProv.errorMessage != null) ...[
                ErrorBanner(
                  message: leaveProv.errorMessage!,
                  onDismiss: () => leaveProv.clearMessages(),
                ),
                const SizedBox(height: 10),
              ],

              // History Title
              Text(
                'My Leave Applications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),

              if (leaveProv.isLoading && leaveProv.myLeaves.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (leaveProv.myLeaves.isEmpty)
                EmptyStateView(
                  icon: Icons.event_available_rounded,
                  title: 'No leave applications yet',
                  buttonText: localeProv.tr('apply_leave'),
                  onButtonPressed: _showApplyLeaveSheet,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leaveProv.myLeaves.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final leave = leaveProv.myLeaves[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StatusBadge(status: leave.leaveType),
                              StatusBadge(status: leave.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '${DateFormat('dd MMM').format(leave.startDate)}  ➔  ${DateFormat('dd MMM yyyy').format(leave.endDate)} (${leave.totalDays} days)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            leave.reason,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (leave.adminComment != null && leave.adminComment!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (leave.isApproved ? AppColors.success : AppColors.error).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    leave.isApproved ? Icons.check_circle_outline : Icons.info_outline,
                                    size: 16,
                                    color: leave.isApproved ? AppColors.success : AppColors.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Admin: ${leave.adminComment}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: leave.isApproved ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}
