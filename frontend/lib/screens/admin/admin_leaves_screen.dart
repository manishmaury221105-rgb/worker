import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/leave_model.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_badge.dart';

class AdminLeavesScreen extends StatefulWidget {
  const AdminLeavesScreen({super.key});

  @override
  State<AdminLeavesScreen> createState() => _AdminLeavesScreenState();
}

class _AdminLeavesScreenState extends State<AdminLeavesScreen> {
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).fetchAllLeaves();
    });
  }

  void _showReviewDialog(LeaveModel leave, String actionStatus) {
    final commentController = TextEditingController();
    final isApproved = actionStatus == 'APPROVED';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isApproved ? AppColors.success : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isApproved ? 'Approve Leave Request' : 'Reject Leave Request',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Worker: ${leave.workerName ?? "Worker"}\nDuration: ${DateFormat('dd MMM').format(leave.startDate)} to ${DateFormat('dd MMM yyyy').format(leave.endDate)} (${leave.totalDays} days)',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Admin Remark / Note (Optional)',
                hint: isApproved ? 'e.g. Approved. Shift covered by Rahul.' : 'e.g. Critical deadline, please reschedule.',
                controller: commentController,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      variant: ButtonVariant.outline,
                      height: 44,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: isApproved ? 'Approve' : 'Reject',
                      variant: isApproved ? ButtonVariant.success : ButtonVariant.danger,
                      height: 44,
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final leaveProv = Provider.of<LeaveProvider>(context, listen: false);
                        await leaveProv.reviewLeave(
                          leaveId: leave.id,
                          status: actionStatus,
                          adminComment: commentController.text.trim(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveProv = Provider.of<LeaveProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredLeaves = leaveProv.allLeaves.where((l) {
      if (_selectedStatus != 'ALL' && l.status != _selectedStatus) return false;
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _StatusTab(
                  label: 'All Leaves (${leaveProv.allLeaves.length})',
                  isSelected: _selectedStatus == 'ALL',
                  onTap: () => setState(() => _selectedStatus = 'ALL'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'Pending (${leaveProv.allLeaves.where((l) => l.isPending).length})',
                  isSelected: _selectedStatus == 'PENDING',
                  onTap: () => setState(() => _selectedStatus = 'PENDING'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'Approved (${leaveProv.allLeaves.where((l) => l.isApproved).length})',
                  isSelected: _selectedStatus == 'APPROVED',
                  onTap: () => setState(() => _selectedStatus = 'APPROVED'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'Rejected (${leaveProv.allLeaves.where((l) => l.isRejected).length})',
                  isSelected: _selectedStatus == 'REJECTED',
                  onTap: () => setState(() => _selectedStatus = 'REJECTED'),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => leaveProv.fetchAllLeaves(),
              child: leaveProv.isLoading && leaveProv.allLeaves.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeaves.isEmpty
                      ? EmptyStateView(
                          icon: Icons.event_available_rounded,
                          title: 'No leave applications found',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredLeaves.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final leave = filteredLeaves[index];

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
                                      Text(
                                        leave.workerName ?? 'Worker Name',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      StatusBadge(status: leave.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${leave.department ?? "General"} • ${leave.leaveType}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${DateFormat('dd MMM').format(leave.startDate)} to ${DateFormat('dd MMM yyyy').format(leave.endDate)} (${leave.totalDays} days)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Reason: ${leave.reason}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),

                                  if (leave.isPending) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            text: 'Reject',
                                            variant: ButtonVariant.danger,
                                            height: 40,
                                            fontSize: 13,
                                            onPressed: () => _showReviewDialog(leave, 'REJECTED'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: CustomButton(
                                            text: 'Approve',
                                            variant: ButtonVariant.success,
                                            height: 40,
                                            fontSize: 13,
                                            onPressed: () => _showReviewDialog(leave, 'APPROVED'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else if (leave.adminComment != null) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Remark: ${leave.adminComment}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: leave.isApproved ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusTab({
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
