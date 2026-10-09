import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/salary_provider.dart';
import '../../widgets/company_logo.dart';
import '../../widgets/stat_card.dart';
import 'admin_workers_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_salary_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchDashboardStats();
      Provider.of<SalaryProvider>(context, listen: false).fetchAllSalaryRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProv = Provider.of<LocaleProvider>(context);
    final adminProv = Provider.of<AdminProvider>(context);
    final salProv = Provider.of<SalaryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = adminProv.dashboardStats;
    final totalPendingSalary = salProv.totalPendingPayout;
    final pendingCount = salProv.pendingPayoutCount;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          adminProv.fetchDashboardStats(),
          salProv.fetchAllSalaryRecords(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0C2461), const Color(0xFF1E3A8A)]
                      : [const Color(0xFF0F2B5C), const Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C2461).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CompanyLogo(
                    size: 46,
                    borderWidth: 2,
                    borderColor: Color(0xFFFBBF24),
                    hasShadow: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'मजबूती भी, सुंदरता भी – बस हमारे साथ !',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // KPI Grid Row 1
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: localeProv.tr('total_workers'),
                    value: '${stats?.totalWorkers ?? 5}',
                    icon: Icons.people_alt_rounded,
                    iconColor: AppColors.primary,
                    subtitle: '${stats?.activeWorkers ?? 5} active',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminWorkersScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: localeProv.tr('present_today'),
                    value: '${stats?.presentToday ?? 3}',
                    icon: Icons.how_to_reg_rounded,
                    iconColor: AppColors.success,
                    subtitle: '${stats?.lateToday ?? 0} late',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total Payout Due (Full-width Card)
            StatCard(
              title: 'Total Payout Due (कुल देय वेतन)',
              value: '₹${totalPendingSalary.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF059669),
              subtitle: totalPendingSalary > 0
                  ? '$pendingCount workers pending'
                  : 'All payments clear',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSalaryScreen()));
              },
            ),
            const SizedBox(height: 16),

            // Department Breakdown Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
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
                  const Text(
                    'Workforce by Department',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  if (stats?.departments != null && stats!.departments.isNotEmpty)
                    ...stats.departments.map(
                      (dept) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dept.name,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${dept.count} workers',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Text('Loading department metrics...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
