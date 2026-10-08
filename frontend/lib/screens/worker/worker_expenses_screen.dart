import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/expense_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';

class WorkerExpensesScreen extends StatefulWidget {
  const WorkerExpensesScreen({super.key});

  @override
  State<WorkerExpensesScreen> createState() => _WorkerExpensesScreenState();
}

class _WorkerExpensesScreenState extends State<WorkerExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).fetchMyExpenses();
    });
  }

  void _showSubmitExpenseSheet() {
    final formKey = GlobalKey<FormState>();
    String category = 'TRAVEL';
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final receiptController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final localeProv = Provider.of<LocaleProvider>(context);
          final expProv = Provider.of<ExpenseProvider>(context);
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
                          localeProv.tr('submit_expense'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      localeProv.tr('expense_category'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CategoryChip(
                          label: '🚗 Travel',
                          isSelected: category == 'TRAVEL',
                          onTap: () => setModalState(() => category = 'TRAVEL'),
                        ),
                        _CategoryChip(
                          label: '🍱 Food',
                          isSelected: category == 'FOOD',
                          onTap: () => setModalState(() => category = 'FOOD'),
                        ),
                        _CategoryChip(
                          label: '🧱 Materials',
                          isSelected: category == 'MATERIALS',
                          onTap: () => setModalState(() => category = 'MATERIALS'),
                        ),
                        _CategoryChip(
                          label: '🔧 Tools',
                          isSelected: category == 'TOOLS',
                          onTap: () => setModalState(() => category = 'TOOLS'),
                        ),
                        _CategoryChip(
                          label: '⛽ Fuel',
                          isSelected: category == 'FUEL',
                          onTap: () => setModalState(() => category = 'FUEL'),
                        ),
                        _CategoryChip(
                          label: '📦 Other',
                          isSelected: category == 'OTHER',
                          onTap: () => setModalState(() => category = 'OTHER'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: localeProv.tr('expense_amount'),
                      hint: 'e.g. 1250',
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.currency_rupee_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter expense amount';
                        if (double.tryParse(v) == null) return 'Enter valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      label: localeProv.tr('expense_desc'),
                      hint: 'e.g. Bus fare for site visit, replacement drill bits...',
                      controller: descController,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      label: 'Bill / Receipt Image URL (Optional)',
                      hint: 'https://...',
                      controller: receiptController,
                      prefixIcon: Icons.receipt_long_outlined,
                    ),
                    const SizedBox(height: 20),

                    CustomButton(
                      text: localeProv.tr('submit'),
                      isLoading: expProv.isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await expProv.submitExpense(
                          category: category,
                          amount: double.parse(amountController.text.trim()),
                          description: descController.text.trim(),
                          receiptUrl: receiptController.text.trim().isNotEmpty
                              ? receiptController.text.trim()
                              : null,
                        );
                        if (success) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Expense claim submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
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
    final localeProv = Provider.of<LocaleProvider>(context);
    final expProv = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => expProv.fetchMyExpenses(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Expense Claimed Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Claims Submitted',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${expProv.myTotalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showSubmitExpenseSheet,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(localeProv.tr('submit_expense')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD97706),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (expProv.errorMessage != null) ...[
                ErrorBanner(message: expProv.errorMessage!),
                const SizedBox(height: 10),
              ],

              const Text(
                'My Expense Claims',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (expProv.isLoading && expProv.myExpenses.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (expProv.myExpenses.isEmpty)
                EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: 'No expense claims yet',
                  buttonText: localeProv.tr('submit_expense'),
                  onButtonPressed: _showSubmitExpenseSheet,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expProv.myExpenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final exp = expProv.myExpenses[index];

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
                              StatusBadge(status: exp.category),
                              StatusBadge(status: exp.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${exp.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
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
                          if (exp.adminComment != null && exp.adminComment!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (exp.isApproved ? AppColors.success : AppColors.error).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Admin: ${exp.adminComment}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: exp.isApproved ? AppColors.success : AppColors.error,
                                ),
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
