import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/utils/attendance_export_helper.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';

class WorkerAttendanceScreen extends StatefulWidget {
  const WorkerAttendanceScreen({super.key});

  @override
  State<WorkerAttendanceScreen> createState() => _WorkerAttendanceScreenState();
}

class _WorkerAttendanceScreenState extends State<WorkerAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attProv = Provider.of<AttendanceProvider>(context, listen: false);
      attProv.fetchTodayAttendance();
      attProv.fetchMyHistory();
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PRESENT':
        return AppColors.success;
      case 'HALF_DAY':
        return Colors.orange;
      case 'LATE':
        return AppColors.warning;
      case 'ABSENT':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusBg(String? status, bool isDark) {
    final baseColor = _getStatusColor(status);
    return baseColor.withOpacity(isDark ? 0.15 : 0.08);
  }

  Color _getStatusBorder(String? status) {
    final baseColor = _getStatusColor(status);
    return baseColor.withOpacity(0.4);
  }

  @override
  Widget build(BuildContext context) {
    final localeProv = Provider.of<LocaleProvider>(context);
    final attProv = Provider.of<AttendanceProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final today = attProv.todayAttendance;
    final isLockedToday = attProv.isTodayLocked || (today != null && today.isLocked);
    final currentStatus = today?.status;

    final presentCount = attProv.history
        .where((a) => a.status == 'PRESENT' || a.status == 'LATE')
        .length;
    final halfDayCount = attProv.history
        .where((a) => a.status == 'HALF_DAY')
        .length;
    final absentCount = attProv.history
        .where((a) => a.status == 'ABSENT')
        .length;

    return RefreshIndicator(
      onRefresh: () async {
        await attProv.fetchTodayAttendance();
        await attProv.fetchMyHistory();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Today Attendance with Dropdown Button Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Today Attendance',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (isLockedToday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_rounded, size: 10, color: Colors.red),
                                      SizedBox(width: 3),
                                      Text('LOCKED', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Status Dropdown Button
                  if (attProv.isCheckingAction)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusBg(currentStatus, isDark),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getStatusBorder(currentStatus),
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ['PRESENT', 'HALF_DAY', 'LATE', 'ABSENT'].contains(currentStatus)
                              ? currentStatus
                              : null,
                          hint: Text(
                            isLockedToday ? 'Locked' : 'Mark Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isLockedToday ? Colors.grey : AppColors.primary,
                            ),
                          ),
                          icon: Icon(
                            isLockedToday ? Icons.lock_rounded : Icons.arrow_drop_down_rounded,
                            size: 20,
                            color: _getStatusColor(currentStatus),
                          ),
                          onChanged: isLockedToday
                              ? null
                              : (newVal) async {
                                  if (newVal != null) {
                                    final ok = await attProv.selfMarkAttendance(status: newVal);
                                    if (ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                              const SizedBox(width: 8),
                                              Text('Today attendance marked as $newVal'),
                                            ],
                                          ),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                          items: const [
                            DropdownMenuItem(
                              value: 'PRESENT',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 15),
                                  SizedBox(width: 6),
                                  Text('Present', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'HALF_DAY',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timelapse_rounded, color: Colors.orange, size: 15),
                                  SizedBox(width: 6),
                                  Text('Half Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'LATE',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.watch_later_rounded, color: AppColors.warning, size: 15),
                                  SizedBox(width: 6),
                                  Text('Late', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ABSENT',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cancel_rounded, color: AppColors.error, size: 15),
                                  SizedBox(width: 6),
                                  Text('Absent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Present Days, Half Days & Absent Days Summary Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Present Days',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$presentCount Days',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.timelapse_rounded, color: Colors.orange, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Half Days',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$halfDayCount Days',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Absent Days',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$absentCount Days',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Messages & Alerts
            if (attProv.errorMessage != null) ...[
              ErrorBanner(
                message: attProv.errorMessage!,
                onDismiss: () => attProv.clearMessages(),
              ),
              const SizedBox(height: 10),
            ],
            if (attProv.successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attProv.successMessage!,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Attendance History Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localeProv.tr('attendance_history'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (attProv.history.isNotEmpty)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 15, color: Colors.white),
                        label: const Text('PDF रिपोर्ट', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: const Size(85, 36),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final authProv = Provider.of<AuthProvider>(context, listen: false);
                          try {
                            await AttendanceExportHelper.exportWorkerHistoryPdf(
                              workerName: authProv.currentUser?.name ?? 'Worker',
                              phone: authProv.currentUser?.phone ?? '',
                              history: attProv.history,
                            );
                          } catch (e) {
                            debugPrint('PDF export error: $e');
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.table_chart_outlined, size: 14),
                        label: const Text('CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: const Size(70, 36),
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final authProv = Provider.of<AuthProvider>(context, listen: false);
                          try {
                            await AttendanceExportHelper.shareWorkerHistoryCsv(
                              workerName: authProv.currentUser?.name ?? 'Worker',
                              phone: authProv.currentUser?.phone ?? '',
                              history: attProv.history,
                            );
                          } catch (e) {
                            debugPrint('CSV export error: $e');
                          }
                        },
                      ),
                    ],
                  )
                else
                  Text(
                    'Last 30 Days',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (attProv.isLoading && attProv.history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (attProv.history.isEmpty)
              EmptyStateView(
                icon: Icons.event_busy_rounded,
                title: localeProv.tr('no_data'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attProv.history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = attProv.history[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEE, dd MMM yyyy').format(item.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.checkInTime != null
                                    ? 'In: ${DateFormat('hh:mm a').format(item.checkInTime!)}  •  Out: ${item.checkOutTime != null ? DateFormat('hh:mm a').format(item.checkOutTime!) : 'Active'}'
                                    : 'No record',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(status: item.status),
                            const SizedBox(height: 4),
                            Text(
                              '${item.workingHours} hrs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
