import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/salary_provider.dart';
import '../../widgets/language_theme_toggle.dart';
import '../auth/login_screen.dart';
import '../common/notifications_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_workers_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_salary_screen.dart';
import 'admin_leaves_screen.dart';
import 'admin_expenses_screen.dart';
import 'admin_reports_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminWorkersScreen(),
    AdminAttendanceScreen(),
    AdminSalaryScreen(),
    AdminLeavesScreen(),
    AdminExpensesScreen(),
    AdminReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchDashboardStats();
      Provider.of<SalaryProvider>(context, listen: false).fetchAllSalaryRecords();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  void _showBroadcastDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String department = 'ALL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final notifProv = Provider.of<NotificationProvider>(context);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.campaign_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Broadcast Announcement',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Title',
                      hintText: 'e.g. Site Safety Meeting Tomorrow',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message Body',
                      hintText: 'All workers must assemble at 9:00 AM at Site Alpha...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: department,
                    decoration: const InputDecoration(labelText: 'Target Department'),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Workers (All Departments)')),
                      DropdownMenuItem(value: 'Electrical', child: Text('Electrical Department')),
                      DropdownMenuItem(value: 'Construction', child: Text('Construction Department')),
                      DropdownMenuItem(value: 'Logistics', child: Text('Logistics Department')),
                      DropdownMenuItem(value: 'Plumbing', child: Text('Plumbing Department')),
                      DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance Department')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => department = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send Broadcast'),
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) return;
                            final success = await notifProv.broadcastNotification(
                              title: titleController.text.trim(),
                              message: messageController.text.trim(),
                              department: department,
                            );
                            if (success) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Broadcast sent to workers successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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
    final authProv = Provider.of<AuthProvider>(context);
    final notifProv = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titles = [
      localeProv.tr('nav_dashboard'),
      localeProv.tr('nav_workers'),
      localeProv.tr('nav_attendance'),
      localeProv.tr('nav_salary'),
      localeProv.tr('nav_leaves'),
      localeProv.tr('nav_expenses'),
      localeProv.tr('nav_reports'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.purple, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_currentIndex],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Admin: ${authProv.currentUser?.name ?? "Rajesh Sharma"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Send Broadcast Announcement',
            onPressed: _showBroadcastDialog,
          ),
          const LanguageThemeToggle(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () async {
              await authProv.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                authProv.currentUser?.name ?? 'Admin Portal',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(authProv.currentUser?.email ?? 'admin@workerapp.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  '👑',
                  style: TextStyle(fontSize: 26),
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.dashboard_rounded,
              title: localeProv.tr('nav_dashboard'),
              isSelected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.people_alt_rounded,
              title: localeProv.tr('nav_workers'),
              isSelected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.fact_check_rounded,
              title: localeProv.tr('nav_attendance'),
              isSelected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.account_balance_wallet_rounded,
              title: localeProv.tr('nav_salary'),
              isSelected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.event_note_rounded,
              title: localeProv.tr('nav_leaves'),
              isSelected: _currentIndex == 4,
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.receipt_long_rounded,
              title: localeProv.tr('nav_expenses'),
              isSelected: _currentIndex == 5,
              onTap: () {
                setState(() => _currentIndex = 5);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.bar_chart_rounded,
              title: localeProv.tr('nav_reports'),
              isSelected: _currentIndex == 6,
              onTap: () {
                setState(() => _currentIndex = 6);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.campaign_rounded, color: AppColors.primary),
              title: const Text('Broadcast Announcement'),
              onTap: () {
                Navigator.pop(context);
                _showBroadcastDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(localeProv.tr('logout'), style: const TextStyle(color: AppColors.error)),
              onTap: () async {
                await authProv.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex >= 4 ? 0 : _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard_rounded),
            label: localeProv.tr('nav_dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_alt_outlined),
            activeIcon: const Icon(Icons.people_alt_rounded),
            label: localeProv.tr('nav_workers'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fact_check_outlined),
            activeIcon: const Icon(Icons.fact_check_rounded),
            label: localeProv.tr('nav_attendance'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: localeProv.tr('nav_salary'),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
