import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_image.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/photo_picker_dialog.dart';
import '../../widgets/status_badge.dart';

class AdminWorkersScreen extends StatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProv = Provider.of<AdminProvider>(context, listen: false);
      adminProv.fetchWorkers();
    });
  }

  void _showPhotoInputDialog({
    required BuildContext parentContext,
    required String title,
    String? currentUrl,
    required Function(String url) onSaved,
  }) {
    PhotoPickerDialog.show(
      context: context,
      title: title,
      currentUrl: currentUrl,
      onSaved: onSaved,
      samplePresets: const [
        {
          'label': 'Sample Aadhaar 1',
          'url': 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=500&auto=format&fit=crop&q=80',
        },
        {
          'label': 'Sample Aadhaar 2',
          'url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80',
        },
      ],
    );
  }

  void _showAddEditWorkerSheet({UserModel? worker}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = worker != null;

    final nameController = TextEditingController(text: worker?.name ?? '');
    final emailController = TextEditingController(text: worker?.email ?? '');
    final phoneController = TextEditingController(text: worker?.phone ?? '');
    final passwordController = TextEditingController(text: isEditing ? '' : 'worker123');
    final salaryController = TextEditingController(text: worker?.monthlySalary.toStringAsFixed(0) ?? '800');
    final addressController = TextEditingController(text: worker?.address ?? '');
    final aadhaarNumberController = TextEditingController(text: worker?.aadhaarNumber ?? '');

    String? aadhaarFrontUrl = worker?.aadhaarFrontUrl;
    String? aadhaarBackUrl = worker?.aadhaarBackUrl;
    String status = worker?.status ?? 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final adminProv = Provider.of<AdminProvider>(context);
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
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
                          isEditing ? 'Edit Worker Profile' : 'Add New Worker',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Full Name',
                      hint: 'e.g. Ramesh Singh',
                      controller: nameController,
                      prefixIcon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Email (Optional)',
                            hint: 'Optional',
                            controller: emailController,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            label: 'Phone Number',
                            hint: '9876543210',
                            controller: phoneController,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (!isEditing) ...[
                      CustomTextField(
                        label: 'Initial Password',
                        hint: 'Default: worker123',
                        controller: passwordController,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 12),
                    ],

                    CustomTextField(
                      label: 'Daily Salary (₹)',
                      controller: salaryController,
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    if (isEditing) ...[
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Account Status'),
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Can Log in & Record Attendance)')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE (Deactivated)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setModalState(() => status = v);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    CustomTextField(
                      label: 'Address',
                      controller: addressController,
                      prefixIcon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),

                    // AADHAAR CARD BOTH SIDE SECTION
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
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
                                child: const Icon(Icons.credit_card_rounded, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Aadhaar Card (आधार कार्ड)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          CustomTextField(
                            label: 'Aadhaar Number (Optional)',
                            hint: 'XXXX XXXX XXXX',
                            controller: aadhaarNumberController,
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            'Attach Aadhaar Photos (दोनों तरफ का फोटो)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              // Front Side Card
                              Expanded(
                                child: _AadhaarUploadBox(
                                  title: 'Front Side (सामने)',
                                  imageUrl: aadhaarFrontUrl,
                                  isDark: isDark,
                                  onTap: () {
                                    _showPhotoInputDialog(
                                      parentContext: context,
                                      title: 'Aadhaar Card - Front Side Photo',
                                      currentUrl: aadhaarFrontUrl,
                                      onSaved: (url) => setModalState(() => aadhaarFrontUrl = url),
                                    );
                                  },
                                  onRemove: aadhaarFrontUrl != null
                                      ? () => setModalState(() => aadhaarFrontUrl = null)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Back Side Card
                              Expanded(
                                child: _AadhaarUploadBox(
                                  title: 'Back Side (पीछे)',
                                  imageUrl: aadhaarBackUrl,
                                  isDark: isDark,
                                  onTap: () {
                                    _showPhotoInputDialog(
                                      parentContext: context,
                                      title: 'Aadhaar Card - Back Side Photo',
                                      currentUrl: aadhaarBackUrl,
                                      onSaved: (url) => setModalState(() => aadhaarBackUrl = url),
                                    );
                                  },
                                  onRemove: aadhaarBackUrl != null
                                      ? () => setModalState(() => aadhaarBackUrl = null)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    CustomButton(
                      text: isEditing ? 'Update Worker Profile' : 'Create Worker Account',
                      isLoading: adminProv.isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        bool success;
                        final salaryVal = double.tryParse(salaryController.text) ?? 800;
                        final phoneVal = phoneController.text.trim();
                        final emailVal = emailController.text.trim().isNotEmpty
                            ? emailController.text.trim()
                            : '$phoneVal@worker.local';

                        if (isEditing) {
                          success = await adminProv.updateWorker(
                            workerId: worker.id,
                            name: nameController.text.trim(),
                            email: emailVal,
                            phone: phoneVal,
                            department: 'General',
                            designation: 'Worker',
                            monthlySalary: salaryVal,
                            hourlyRate: salaryVal / 8.0,
                            status: status,
                            address: addressController.text.trim(),
                            emergencyContact: '',
                            aadhaarNumber: aadhaarNumberController.text.trim(),
                            aadhaarFrontUrl: aadhaarFrontUrl,
                            aadhaarBackUrl: aadhaarBackUrl,
                          );
                        } else {
                          success = await adminProv.createWorker(
                            name: nameController.text.trim(),
                            email: emailVal,
                            phone: phoneVal,
                            password: passwordController.text.trim().isNotEmpty ? passwordController.text.trim() : 'worker123',
                            department: 'General',
                            designation: 'Worker',
                            monthlySalary: salaryVal,
                            hourlyRate: salaryVal / 8.0,
                            address: addressController.text.trim(),
                            emergencyContact: '',
                            aadhaarNumber: aadhaarNumberController.text.trim(),
                            aadhaarFrontUrl: aadhaarFrontUrl,
                            aadhaarBackUrl: aadhaarBackUrl,
                          );
                        }
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

  void _showWorkerDetails(UserModel worker) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          worker.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          Text('₹${worker.monthlySalary.toStringAsFixed(0)}/day', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              _InfoRow(label: 'Phone Number', value: worker.phone, icon: Icons.phone_outlined),
              _InfoRow(label: 'Email', value: worker.email, icon: Icons.email_outlined),
              if (worker.address != null && worker.address!.isNotEmpty)
                _InfoRow(label: 'Address', value: worker.address!, icon: Icons.home_outlined),
              if (worker.aadhaarNumber != null && worker.aadhaarNumber!.isNotEmpty)
                _InfoRow(label: 'Aadhaar Number', value: worker.aadhaarNumber!, icon: Icons.credit_card_rounded),

              const SizedBox(height: 16),
              // Aadhaar Photos Display
              const Text('Aadhaar Card Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _AadhaarViewThumb(
                      title: 'Front Side',
                      imageUrl: worker.aadhaarFrontUrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AadhaarViewThumb(
                      title: 'Back Side',
                      imageUrl: worker.aadhaarBackUrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: 'Edit Worker Profile',
                icon: Icons.edit_rounded,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showAddEditWorkerSheet(worker: worker);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(UserModel worker) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Worker?'),
        content: Text('Are you sure you want to delete ${worker.name}? This will remove their profile and records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Provider.of<AdminProvider>(context, listen: false).deleteWorker(worker.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = _searchController.text.trim().toLowerCase();
    final filteredWorkers = adminProv.workers.where((w) {
      if (query.isNotEmpty) {
        final matchesName = w.name.toLowerCase().contains(query);
        final matchesPhone = w.phone.contains(query);
        final matchesAadhaar = w.aadhaarNumber?.contains(query) ?? false;
        return matchesName || matchesPhone || matchesAadhaar;
      }
      return true;
    }).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => adminProv.fetchWorkers(),
        child: Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: CustomTextField(
                hint: 'Search workers by name, phone, Aadhaar...',
                controller: _searchController,
                prefixIcon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),

            if (adminProv.errorMessage != null) ...[
              ErrorBanner(message: adminProv.errorMessage!),
              const SizedBox(height: 8),
            ],

            Expanded(
              child: adminProv.isLoading && adminProv.workers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredWorkers.isEmpty
                      ? EmptyStateView(
                          icon: Icons.people_outline_rounded,
                          title: 'No workers found',
                          buttonText: 'Add New Worker',
                          onButtonPressed: () => _showAddEditWorkerSheet(),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredWorkers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final worker = filteredWorkers[index];
                            final hasAadhaar = (worker.aadhaarFrontUrl != null && worker.aadhaarFrontUrl!.isNotEmpty) ||
                                (worker.aadhaarBackUrl != null && worker.aadhaarBackUrl!.isNotEmpty);

                            return InkWell(
                              onTap: () => _showWorkerDetails(worker),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primary.withOpacity(0.12),
                                      child: Text(
                                        worker.name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  worker.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                              ),
                                              StatusBadge(status: worker.status),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                '📞 ${worker.phone}  |  ₹${worker.monthlySalary.toStringAsFixed(0)}/day',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                              if (hasAadhaar) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Row(
                                                    children: [
                                                      Icon(Icons.credit_card_rounded, size: 11, color: AppColors.primary),
                                                      SizedBox(width: 2),
                                                      Text('Aadhaar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      onSelected: (val) {
                                        if (val == 'details') {
                                          _showWorkerDetails(worker);
                                        } else if (val == 'edit') {
                                          _showAddEditWorkerSheet(worker: worker);
                                        } else if (val == 'delete') {
                                          _confirmDelete(worker);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'details', child: Text('View Details & Aadhaar')),
                                        const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Worker', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditWorkerSheet(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Worker', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _AadhaarUploadBox extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _AadhaarUploadBox({
    required this.title,
    required this.imageUrl,
    required this.isDark,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.success : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: hasImage ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    imageSource: imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '+ Add Photo',
                    style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AadhaarViewThumb extends StatelessWidget {
  final String title;
  final String? imageUrl;

  const _AadhaarViewThumb({
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  imageSource: imageUrl,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                '$title\nNot Uploaded',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
