import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import '../auth/change_password_dialog.dart';
import '../auth/login_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  void _showEditProfileSheet() {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final user = authProv.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final addressController = TextEditingController(text: user.address ?? '');
    final emergencyController = TextEditingController(text: user.emergencyContact ?? '');
    final bankController = TextEditingController(text: user.bankAccount ?? '');
    final upiController = TextEditingController(text: user.upiId ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Personal Profile',
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
                  label: 'Full Name',
                  controller: nameController,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Phone Number',
                  controller: phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Emergency Contact',
                  controller: emergencyController,
                  prefixIcon: Icons.contact_phone_outlined,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Residential Address',
                  controller: addressController,
                  prefixIcon: Icons.home_outlined,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Bank Account Details',
                  controller: bankController,
                  prefixIcon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'UPI ID',
                  controller: upiController,
                  prefixIcon: Icons.payment_outlined,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Save Profile Changes',
                  onPressed: () async {
                    final success = await authProv.updateProfile(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                      emergencyContact: emergencyController.text.trim(),
                      bankAccount: bankController.text.trim(),
                      upiId: upiController.text.trim(),
                    );
                    if (success) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProv = Provider.of<LocaleProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authProv.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(
                        (user?.name ?? 'W').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Worker Name',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user?.designation ?? "Worker"} • ${user?.department ?? "General"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StatusBadge(status: user?.status ?? 'ACTIVE'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Edit Profile Information',
                  icon: Icons.edit_outlined,
                  variant: ButtonVariant.outline,
                  height: 44,
                  fontSize: 13,
                  onPressed: _showEditProfileSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact & Bank Details
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Work & Contact Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _InfoItem(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '-'),
                _InfoItem(icon: Icons.phone_outlined, label: 'Phone', value: user?.phone ?? '-'),
                _InfoItem(icon: Icons.contact_phone_outlined, label: 'Emergency Contact', value: user?.emergencyContact ?? 'Not provided'),
                _InfoItem(icon: Icons.home_outlined, label: 'Address', value: user?.address ?? 'Not provided'),
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joining Date',
                  value: user?.dateOfJoining != null
                      ? DateFormat('dd MMMM yyyy').format(user!.dateOfJoining!)
                      : 'October 2026',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bank & Payout Information
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Banking & Payment Method',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _InfoItem(icon: Icons.account_balance_outlined, label: 'Bank Account', value: user?.bankAccount ?? 'Not provided'),
                _InfoItem(icon: Icons.payment_outlined, label: 'UPI ID', value: user?.upiId ?? 'Not provided'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings & Preferences
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Preferences',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Language Toggle Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.language_rounded, size: 20, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('App Language (भाषा)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    DropdownButton<String>(
                      value: localeProv.currentLocale,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English (EN)')),
                        DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                      ],
                      onChanged: (val) {
                        if (val != null) localeProv.setLocale(val);
                      },
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Dark Mode Switch Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          themeProv.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(localeProv.tr('dark_mode'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Switch(
                      value: themeProv.isDarkMode,
                      activeColor: AppColors.primary,
                      onChanged: (_) => themeProv.toggleTheme(),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Change Password
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.primary),
                  title: Text(localeProv.tr('change_password'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ChangePasswordDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Official Company Information Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0C2461), const Color(0xFF071739)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E3560) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.business_rounded, color: Color(0xFFF59E0B), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          Text(
                            'मजबूती भी, सुंदरता भी – बस हमारे साथ !',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _InfoItem(
                  icon: Icons.phone_android_rounded,
                  label: 'संपर्क / Mobile',
                  value: 'अजय मौर्य: 9695718820\nविजय मौर्य: 9892826110',
                ),
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: 'पता / Workshop Address',
                  value: 'घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर',
                ),
                _InfoItem(
                  icon: Icons.handyman_outlined,
                  label: 'सेवाएं / Services',
                  value: 'एल्युमिनियम दरवाजे, खिड़की, पार्टिशन डोर, इम्पोर्टेड जाली, ग्लास वर्क',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          CustomButton(
            text: localeProv.tr('logout'),
            icon: Icons.logout_rounded,
            variant: ButtonVariant.danger,
            onPressed: () async {
              await authProv.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
