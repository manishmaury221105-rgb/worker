import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_badge.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchAllTasks();
      Provider.of<AdminProvider>(context, listen: false).fetchWorkers();
    });
  }

  void _showCreateTaskSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 2));
    String priority = 'MEDIUM';

    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    String? selectedWorkerId = adminProv.workers.isNotEmpty ? adminProv.workers.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final taskProv = Provider.of<TaskProvider>(context);

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
                          'Assign New Task',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Task Title',
                      hint: 'e.g. Repair Main Substation Breaker',
                      controller: titleController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedWorkerId,
                      decoration: const InputDecoration(labelText: 'Assign To Worker'),
                      items: adminProv.workers.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text('${w.name} (${w.designation} - ${w.department})'),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedWorkerId = v),
                      validator: (v) => v == null ? 'Select a worker' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priority,
                            decoration: const InputDecoration(labelText: 'Priority Level'),
                            items: const [
                              DropdownMenuItem(value: 'URGENT', child: Text('🔴 URGENT')),
                              DropdownMenuItem(value: 'HIGH', child: Text('🟠 HIGH')),
                              DropdownMenuItem(value: 'MEDIUM', child: Text('🔵 MEDIUM')),
                              DropdownMenuItem(value: 'LOW', child: Text('🟢 LOW')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => priority = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setModalState(() => dueDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Due Date',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(dueDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Work Location / Zone',
                      hint: 'e.g. Sector 18 Substation, Gurugram',
                      controller: locationController,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Detailed Instructions',
                      hint: 'Specify requirements, tools needed, and steps to follow...',
                      controller: descController,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 20),

                    CustomButton(
                      text: 'Create & Assign Task',
                      isLoading: taskProv.isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate() || selectedWorkerId == null) return;
                        final success = await taskProv.createTask(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          assignedToId: selectedWorkerId!,
                          priority: priority,
                          dueDate: dueDate,
                          location: locationController.text.trim(),
                        );
                        if (success) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task assigned to worker with instant notification!'),
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
    final taskProv = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTasks = taskProv.allTasks.where((t) {
      if (_selectedStatus != 'ALL' && t.status != _selectedStatus) return false;
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
                  label: 'All Tasks (${taskProv.allTasks.length})',
                  isSelected: _selectedStatus == 'ALL',
                  onTap: () => setState(() => _selectedStatus = 'ALL'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'Pending (${taskProv.allTasks.where((t) => t.isPending).length})',
                  isSelected: _selectedStatus == 'PENDING',
                  onTap: () => setState(() => _selectedStatus = 'PENDING'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'In Progress (${taskProv.allTasks.where((t) => t.isInProgress).length})',
                  isSelected: _selectedStatus == 'IN_PROGRESS',
                  onTap: () => setState(() => _selectedStatus = 'IN_PROGRESS'),
                ),
                const SizedBox(width: 8),
                _StatusTab(
                  label: 'Completed (${taskProv.allTasks.where((t) => t.isCompleted).length})',
                  isSelected: _selectedStatus == 'COMPLETED',
                  onTap: () => setState(() => _selectedStatus = 'COMPLETED'),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => taskProv.fetchAllTasks(),
              child: taskProv.isLoading && taskProv.allTasks.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTasks.isEmpty
                      ? EmptyStateView(
                          icon: Icons.assignment_outlined,
                          title: 'No tasks found',
                          buttonText: 'Assign New Task',
                          onButtonPressed: _showCreateTaskSheet,
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
                                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      StatusBadge(status: task.priority),
                                      Row(
                                        children: [
                                          StatusBadge(status: task.status),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => taskProv.deleteTask(task.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    task.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

                                  // Assigned worker info
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 16, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Assigned: ${task.workerName ?? "Worker"}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (task.dueDate != null)
                                          Text(
                                            'Due: ${DateFormat('dd MMM').format(task.dueDate!)}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (task.completionNotes != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Completion Notes: ${task.completionNotes}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskSheet,
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Assign Task', style: TextStyle(fontWeight: FontWeight.bold)),
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
          color: isSelected ? AppColors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.purple : AppColors.borderLight,
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
