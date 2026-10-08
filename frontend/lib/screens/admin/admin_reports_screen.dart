import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/stat_card.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final stats = adminProv.dashboardStats;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalWorkers = stats?.totalWorkers ?? 5;
    final presentToday = stats?.presentToday ?? 4;
    final lateToday = stats?.lateToday ?? 1;
    final totalHours = stats?.totalWorkingHours ?? 1092;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => adminProv.fetchDashboardStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Monthly Summary Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Operations & Payroll Analytics',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(DateTime.now()),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Hours Logged', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('$totalHours hrs', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Attendance Rate', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('${stats?.attendanceRate ?? 80}%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Metrics Row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'On-Time Today',
                      value: '${(presentToday - lateToday).clamp(0, 999)}',
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                      subtitle: 'Punctual workers',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Late Today',
                      value: '$lateToday',
                      icon: Icons.access_time_filled_rounded,
                      iconColor: AppColors.warning,
                      subtitle: 'Delayed check-in',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Attendance Distribution Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Attendance Breakdown',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _ProgressBarRow(
                      label: 'Present On Site',
                      count: presentToday,
                      total: totalWorkers,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    _ProgressBarRow(
                      label: 'Late Check-ins',
                      count: lateToday,
                      total: totalWorkers,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    _ProgressBarRow(
                      label: 'Pending / Absent',
                      count: stats?.absentToday ?? 1,
                      total: totalWorkers,
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Departmental Workforce Share
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Department Distribution',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    if (stats?.departments != null)
                      ...stats!.departments.map(
                        (d) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 5,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: totalWorkers > 0 ? (d.count / totalWorkers) : 0,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.withOpacity(0.15),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('${d.count} (${totalWorkers > 0 ? (d.count * 100 ~/ totalWorkers) : 0}%)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _ProgressBarRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('$count workers (${(percent * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
