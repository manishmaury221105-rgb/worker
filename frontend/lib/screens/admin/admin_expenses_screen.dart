import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_badge.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).fetchAllExpenses();
    });
  }

  void _showReviewDialog(ExpenseModel expense, String actionStatus) {
    final commentController = TextEditingController();
    final isApproved = actionStatus == 'APPROVED' || actionStatus == 'REIMBURSED';

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
              Text(
                isApproved ? 'Approve & Reimburse Expense' : 'Reject Expense Claim',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Worker: ${expense.workerName ?? "Worker"}\nAmount: ₹${expense.amount.toStringAsFixed(0)} (${expense.category})\nDesc: ${expense.description}',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Admin Remark (Optional)',
                hint: isApproved ? 'e.g. Receipt verified. Reimbursed via UPI.' : 'e.g. Missing valid receipt.',
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
                        final expProv = Provider.of<ExpenseProvider>(context, listen: false);
                        await expProv.reviewExpense(
                          expenseId: expense.id,
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
    final expProv = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredExpenses = expProv.allExpenses.where((e) {
      if (_selectedStatus != 'ALL' && e.status != _selectedStatus) return false;
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Total Sum Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Expense Claims', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '₹${expProv.allTotalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${expProv.allExpenses.where((e) => e.isPending).length} Pending',
                    style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _StatusTab(
                  label: 'All (${expProv.allExpenses.length})',
                  isSelected: _selectedStatus == 'ALL',
                  onTap: () => setState(() => _selectedStatus = 'ALL'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'Pending (${expProv.allExpenses.where((e) => e.isPending).length})',
                  isSelected: _selectedStatus == 'PENDING',
                  onTap: () => setState(() => _selectedStatus = 'PENDING'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'Approved (${expProv.allExpenses.where((e) => e.isApproved).length})',
                  isSelected: _selectedStatus == 'APPROVED',
                  onTap: () => setState(() => _selectedStatus = 'APPROVED'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'Reimbursed (${expProv.allExpenses.where((e) => e.isReimbursed).length})',
                  isSelected: _selectedStatus == 'REIMBURSED',
                  onTap: () => setState(() => _selectedStatus = 'REIMBURSED'),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => expProv.fetchAllExpenses(),
              child: expProv.isLoading && expProv.allExpenses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredExpenses.isEmpty
                      ? EmptyStateView(
                          icon: Icons.receipt_long_outlined,
                          title: 'No expense claims found',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredExpenses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final exp = filteredExpenses[index];

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
                                        exp.workerName ?? 'Worker Name',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      StatusBadge(status: exp.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exp.department ?? "General"} • ${exp.category}',
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
                                        '₹${exp.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(exp.expenseDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    exp.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (exp.isPending) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            text: 'Reject',
                                            variant: ButtonVariant.danger,
                                            height: 38,
                                            fontSize: 12,
                                            onPressed: () => _showReviewDialog(exp, 'REJECTED'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: CustomButton(
                                            text: 'Approve Claim',
                                            variant: ButtonVariant.success,
                                            height: 38,
                                            fontSize: 12,
                                            onPressed: () => _showReviewDialog(exp, 'APPROVED'),
                                          ),
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
