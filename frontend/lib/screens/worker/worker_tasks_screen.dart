import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';
import '../../providers/locale_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_badge.dart';

class WorkerTasksScreen extends StatefulWidget {
  const WorkerTasksScreen({super.key});

  @override
  State<WorkerTasksScreen> createState() => _WorkerTasksScreenState();
}

class _WorkerTasksScreenState extends State<WorkerTasksScreen> {
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchMyTasks();
    });
  }

  void _showCompleteDialog(TaskModel task) {
    final notesController = TextEditingController();
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);
    final taskProv = Provider.of<TaskProvider>(context, listen: false);

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
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localeProv.tr('mark_complete'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: localeProv.tr('completion_notes'),
                hint: 'e.g. Completed wiring and tested load...',
                controller: notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: localeProv.tr('cancel'),
                      variant: ButtonVariant.outline,
                      height: 44,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: localeProv.tr('confirm'),
                      variant: ButtonVariant.success,
                      height: 44,
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await taskProv.updateTaskStatus(
                          taskId: task.id,
                          status: 'COMPLETED',
                          completionNotes: notesController.text.trim(),
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
    final localeProv = Provider.of<LocaleProvider>(context);
    final taskProv = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTasks = taskProv.myTasks.where((t) {
      if (_selectedStatus == 'ALL') return true;
      return t.status == _selectedStatus;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => taskProv.fetchMyTasks(),
      child: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: localeProv.tr('all'),
                    isSelected: _selectedStatus == 'ALL',
                    count: taskProv.myTasks.length,
                    onTap: () => setState(() => _selectedStatus = 'ALL'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: localeProv.tr('in_progress'),
                    isSelected: _selectedStatus == 'IN_PROGRESS',
                    count: taskProv.myTasks.where((t) => t.status == 'IN_PROGRESS').length,
                    onTap: () => setState(() => _selectedStatus = 'IN_PROGRESS'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: localeProv.tr('pending'),
                    isSelected: _selectedStatus == 'PENDING',
                    count: taskProv.myTasks.where((t) => t.status == 'PENDING').length,
                    onTap: () => setState(() => _selectedStatus = 'PENDING'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: localeProv.tr('completed'),
                    isSelected: _selectedStatus == 'COMPLETED',
                    count: taskProv.myTasks.where((t) => t.status == 'COMPLETED').length,
                    onTap: () => setState(() => _selectedStatus = 'COMPLETED'),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: taskProv.isLoading && taskProv.myTasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? EmptyStateView(
                        icon: Icons.task_alt_rounded,
                        title: localeProv.tr('no_data'),
                        buttonText: localeProv.tr('refresh'),
                        onButtonPressed: () => taskProv.fetchMyTasks(),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: task.priority == 'URGENT'
                                    ? AppColors.error.withOpacity(0.4)
                                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                width: task.priority == 'URGENT' ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                  blurRadius: 10,
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
                                    StatusBadge(status: task.priority),
                                    StatusBadge(status: task.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Location & Due Date Info
                                Row(
                                  children: [
                                    if (task.location != null) ...[
                                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          task.location!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    if (task.dueDate != null) ...[
                                      const Icon(Icons.calendar_month_outlined, size: 15, color: AppColors.warning),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due: ${DateFormat('MMM d').format(task.dueDate!)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Actions
                                if (!task.isCompleted) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (task.isPending)
                                        Expanded(
                                          child: CustomButton(
                                            text: 'Start Task',
                                            variant: ButtonVariant.outline,
                                            height: 40,
                                            fontSize: 13,
                                            onPressed: () => taskProv.updateTaskStatus(
                                              taskId: task.id,
                                              status: 'IN_PROGRESS',
                                            ),
                                          ),
                                        ),
                                      if (task.isPending) const SizedBox(width: 10),
                                      Expanded(
                                        child: CustomButton(
                                          text: localeProv.tr('mark_complete'),
                                          variant: ButtonVariant.success,
                                          height: 40,
                                          fontSize: 13,
                                          icon: Icons.check,
                                          onPressed: () => _showCompleteDialog(task),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (task.completionNotes != null && task.completionNotes!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.notes_rounded, size: 16, color: AppColors.success),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Notes: ${task.completionNotes}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.success),
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
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.count,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
