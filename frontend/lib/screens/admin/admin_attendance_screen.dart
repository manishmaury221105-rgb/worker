import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../core/utils/attendance_export_helper.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
      Provider.of<AdminProvider>(context, listen: false).fetchWorkers();
    });
  }

  void _loadAttendance() {
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    attProv.fetchAllAttendance(date: dateStr, status: _selectedStatus);
    attProv.fetchLockStatus(date: dateStr);
  }

  Future<void> _updateWorkerStatus({
    required String userId,
    required String workerName,
    required String newStatus,
    AttendanceModel? existingRecord,
  }) async {
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    double hours = 8.0;
    if (newStatus == 'ABSENT') {
      hours = 0.0;
    } else if (newStatus == 'HALF_DAY') {
      hours = 4.0;
    } else {
      hours = existingRecord?.workingHours ?? 8.0;
      if (hours <= 0) hours = 8.0;
    }

    DateTime? inTime = existingRecord?.checkInTime;
    DateTime? outTime = existingRecord?.checkOutTime;

    if (newStatus != 'ABSENT') {
      if (inTime == null) {
        inTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 9, 0);
      }
      if (outTime == null && (newStatus == 'HALF_DAY' || newStatus == 'PRESENT')) {
        outTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 17, 30);
      }
    } else {
      inTime = null;
      outTime = null;
    }

    final success = await attProv.manualMarkAttendance(
      userId: userId,
      date: dateStr,
      status: newStatus,
      workingHours: hours,
      checkInTime: inTime,
      checkOutTime: outTime,
      notes: 'Status set to $newStatus by Admin dropdown',
    );

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$workerName marked as $newStatus'),
              ),
            ],
          ),
        ),
      );
      _loadAttendance();
    }
  }

  Future<void> _showFullEditModal({AttendanceModel? existingRecord, UserModel? worker}) async {
    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);

    if (adminProv.workers.isEmpty) {
      await adminProv.fetchWorkers();
    }

    String? selectedWorkerId = existingRecord?.userId ??
        worker?.id ??
        (adminProv.workers.isNotEmpty ? adminProv.workers.first.id : null);

    String status = existingRecord?.status ?? 'PRESENT';
    DateTime targetDate = existingRecord?.date ?? _selectedDate;

    TimeOfDay inTime = existingRecord?.checkInTime != null
        ? TimeOfDay.fromDateTime(existingRecord!.checkInTime!)
        : const TimeOfDay(hour: 9, minute: 0);

    TimeOfDay outTime = existingRecord?.checkOutTime != null
        ? TimeOfDay.fromDateTime(existingRecord!.checkOutTime!)
        : const TimeOfDay(hour: 17, minute: 30);

    final hoursController = TextEditingController(
      text: existingRecord != null ? existingRecord.workingHours.toStringAsFixed(1) : '8.5',
    );
    final notesController = TextEditingController(
      text: existingRecord?.notes ?? 'Admin manual entry',
    );

    void calculateHours(TimeOfDay checkIn, TimeOfDay checkOut, Function setStateCallback) {
      final now = DateTime.now();
      final dtIn = DateTime(now.year, now.month, now.day, checkIn.hour, checkIn.minute);
      var dtOut = DateTime(now.year, now.month, now.day, checkOut.hour, checkOut.minute);
      if (dtOut.isBefore(dtIn)) {
        dtOut = dtOut.add(const Duration(days: 1));
      }
      final diff = dtOut.difference(dtIn).inMinutes / 60.0;
      hoursController.text = diff > 0 ? diff.toStringAsFixed(1) : '8.0';
      setStateCallback(() {});
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            existingRecord != null ? 'Edit Details' : 'Manual Attendance Entry',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Worker Selector
                  const Text('Worker', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedWorkerId,
                        isExpanded: true,
                        hint: const Text('Select Worker'),
                        items: adminProv.workers.map((w) {
                          return DropdownMenuItem(
                            value: w.id,
                            child: Text('${w.name} (${w.department})'),
                          );
                        }).toList(),
                        onChanged: existingRecord != null ? null : (v) => setModalState(() => selectedWorkerId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status Selector
                  const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('PRESENT', 'Present', AppColors.success, status, (s) => setModalState(() => status = s)),
                      _buildChip('LATE', 'Late', AppColors.warning, status, (s) => setModalState(() => status = s)),
                      _buildChip('HALF_DAY', 'Half Day', Colors.amber.shade700, status, (s) {
                        setModalState(() {
                          status = s;
                          hoursController.text = '4.0';
                        });
                      }),
                      _buildChip('ABSENT', 'Absent', AppColors.error, status, (s) {
                        setModalState(() {
                          status = s;
                          hoursController.text = '0.0';
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (status != 'ABSENT') ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Check-In Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(context: context, initialTime: inTime);
                                  if (picked != null) {
                                    setModalState(() {
                                      inTime = picked;
                                      calculateHours(inTime, outTime, setModalState);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                    borderRadius: BorderRadius.circular(10),
                                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.login_rounded, size: 16, color: AppColors.success),
                                      const SizedBox(width: 8),
                                      Text(inTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Check-Out Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(context: context, initialTime: outTime);
                                  if (picked != null) {
                                    setModalState(() {
                                      outTime = picked;
                                      calculateHours(inTime, outTime, setModalState);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                    borderRadius: BorderRadius.circular(10),
                                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                                      const SizedBox(width: 8),
                                      Text(outTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  CustomTextField(
                    label: 'Working Hours',
                    controller: hoursController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.timer_outlined,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    label: 'Remarks / Notes',
                    controller: notesController,
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Save Record',
                    isLoading: attProv.isLoading,
                    onPressed: () async {
                      if (selectedWorkerId == null) return;

                      DateTime? checkInDt;
                      DateTime? checkOutDt;

                      if (status != 'ABSENT') {
                        checkInDt = DateTime(targetDate.year, targetDate.month, targetDate.day, inTime.hour, inTime.minute);
                        checkOutDt = DateTime(targetDate.year, targetDate.month, targetDate.day, outTime.hour, outTime.minute);
                        if (checkOutDt.isBefore(checkInDt)) {
                          checkOutDt = checkOutDt.add(const Duration(days: 1));
                        }
                      }

                      final success = await attProv.manualMarkAttendance(
                        userId: selectedWorkerId!,
                        date: DateFormat('yyyy-MM-dd').format(targetDate),
                        status: status,
                        checkInTime: checkInDt,
                        checkOutTime: checkOutDt,
                        workingHours: double.tryParse(hoursController.text) ?? (status == 'ABSENT' ? 0.0 : 8.0),
                        notes: notesController.text.trim(),
                      );

                      if (context.mounted && success) {
                        Navigator.of(ctx).pop();
                        _loadAttendance();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String value, String label, Color color, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: isSelected ? 2 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attProv = Provider.of<AttendanceProvider>(context);
    final adminProv = Provider.of<AdminProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Map existing attendance records by worker userId
    final attendanceMap = <String, AttendanceModel>{};
    for (final a in attProv.allAttendance) {
      attendanceMap[a.userId] = a;
    }

    // Build complete list of items: if ALL filter, show all workers (marked + unmarked)
    // If specific filter (PRESENT, LATE, etc.), show matching logged records
    List<Widget> listItems = [];

    if (_selectedStatus == 'ALL') {
      // Show all workers with their attendance status
      final allWorkers = adminProv.workers;

      listItems = allWorkers.map((worker) {
        final log = attendanceMap[worker.id];
        final currentStatus = log?.status ?? 'NOT_MARKED';

        return _buildWorkerAttendanceCard(
          workerName: worker.name,
          designation: worker.designation,
          department: worker.department,
          userId: worker.id,
          status: currentStatus,
          checkInTime: log?.checkInTime,
          checkOutTime: log?.checkOutTime,
          workingHours: log?.workingHours ?? 0.0,
          address: log?.checkInAddress,
          notes: log?.notes,
          existingRecord: log,
          worker: worker,
          isDark: isDark,
        );
      }).toList();
    } else {
      // Filtered list
      listItems = attProv.allAttendance.map((log) {
        return _buildWorkerAttendanceCard(
          workerName: log.workerName ?? 'Worker',
          designation: log.designation ?? 'Worker',
          department: log.department ?? '',
          userId: log.userId,
          status: log.status,
          checkInTime: log.checkInTime,
          checkOutTime: log.checkOutTime,
          workingHours: log.workingHours,
          address: log.checkInAddress,
          notes: log.notes,
          existingRecord: log,
          isDark: isDark,
        );
      }).toList();
    }

    return Scaffold(
      body: Column(
        children: [
          // Date Filter & Actions Header
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadAttendance();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final newLockState = !attProv.isDateLocked;
                    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                    final ok = await attProv.toggleAttendanceLock(date: dateStr, isLocked: newLockState);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(newLockState ? Icons.lock_rounded : Icons.lock_open_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  newLockState
                                      ? 'Attendance for ${DateFormat('dd MMM').format(_selectedDate)} LOCKED! Workers cannot edit.'
                                      : 'Attendance for ${DateFormat('dd MMM').format(_selectedDate)} UNLOCKED!',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: newLockState ? Colors.red : AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      _loadAttendance();
                    }
                  },
                  icon: Icon(
                    attProv.isDateLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 18,
                    color: attProv.isDateLocked ? Colors.red : Colors.grey[700],
                  ),
                  label: Text(
                    attProv.isDateLocked ? 'LOCKED' : 'Lock (लॉक करें)',
                    style: TextStyle(
                      color: attProv.isDateLocked ? Colors.red : null,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: attProv.isDateLocked ? Colors.red : null,
                    side: BorderSide(
                      color: attProv.isDateLocked ? Colors.red : Colors.grey[400]!,
                      width: 1.5,
                    ),
                    backgroundColor: attProv.isDateLocked ? Colors.red.withOpacity(0.08) : null,
                    minimumSize: const Size(100, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await AttendanceExportHelper.exportAdminDailyReportPdf(
                        date: _selectedDate,
                        workers: adminProv.workers,
                        attendances: attProv.allAttendance,
                      );
                    } catch (e) {
                      debugPrint('PDF export error: $e');
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.redAccent),
                  label: const Text('PDF रिपोर्ट', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    minimumSize: const Size(105, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await AttendanceExportHelper.shareAdminDailyReportCsv(
                        date: _selectedDate,
                        workers: adminProv.workers,
                        attendances: attProv.allAttendance,
                      );
                    } catch (e) {
                      debugPrint('CSV export error: $e');
                    }
                  },
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text('CSV / Excel', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success, width: 1.5),
                    minimumSize: const Size(95, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // Lock Indicator Banner if locked
          if (attProv.isDateLocked)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🔒 Attendance for ${DateFormat('EEEE, dd MMM yyyy').format(_selectedDate)} is LOCKED by Admin (हाजिरी लॉक है). Workers cannot mark or modify attendance.',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _StatusFilterChip(
                  label: 'All Workers (${adminProv.workers.isNotEmpty ? adminProv.workers.length : attProv.allAttendance.length})',
                  isSelected: _selectedStatus == 'ALL',
                  onTap: () {
                    setState(() => _selectedStatus = 'ALL');
                    _loadAttendance();
                  },
                ),
                const SizedBox(width: 6),
                _StatusFilterChip(
                  label: 'Present',
                  isSelected: _selectedStatus == 'PRESENT',
                  onTap: () {
                    setState(() => _selectedStatus = 'PRESENT');
                    _loadAttendance();
                  },
                ),
                const SizedBox(width: 6),
                _StatusFilterChip(
                  label: 'Late',
                  isSelected: _selectedStatus == 'LATE',
                  onTap: () {
                    setState(() => _selectedStatus = 'LATE');
                    _loadAttendance();
                  },
                ),
                const SizedBox(width: 6),
                _StatusFilterChip(
                  label: 'Half Day',
                  isSelected: _selectedStatus == 'HALF_DAY',
                  onTap: () {
                    setState(() => _selectedStatus = 'HALF_DAY');
                    _loadAttendance();
                  },
                ),
                const SizedBox(width: 6),
                _StatusFilterChip(
                  label: 'Absent',
                  isSelected: _selectedStatus == 'ABSENT',
                  onTap: () {
                    setState(() => _selectedStatus = 'ABSENT');
                    _loadAttendance();
                  },
                ),
              ],
            ),
          ),

          // Table / List View with Inline Status Dropdown
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadAttendance();
                await adminProv.fetchWorkers();
              },
              child: attProv.isLoading && listItems.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : listItems.isEmpty
                      ? EmptyStateView(
                          icon: Icons.event_note_rounded,
                          title: 'No attendance records found',
                          buttonText: 'Add Attendance',
                          onButtonPressed: () => _showFullEditModal(),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: listItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => listItems[index],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerAttendanceCard({
    required String workerName,
    required String designation,
    required String department,
    required String userId,
    required String status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    required double workingHours,
    String? address,
    String? notes,
    AttendanceModel? existingRecord,
    UserModel? worker,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'NOT_MARKED'
              ? (isDark ? AppColors.borderDark : AppColors.borderLight)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Worker Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      workerName.isNotEmpty ? workerName.substring(0, 1).toUpperCase() : 'W',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '$designation • $department',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // INLINE DROPDOWN BADGE RIGHT HERE
              _AttendanceInlineDropdown(
                status: status,
                onStatusChanged: (newStatus) {
                  _updateWorkerStatus(
                    userId: userId,
                    workerName: workerName,
                    newStatus: newStatus,
                    existingRecord: existingRecord,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timestamps & Working Hours
          Row(
            children: [
              Expanded(
                child: Text(
                  'In: ${checkInTime != null ? DateFormat('hh:mm a').format(checkInTime) : (status == "NOT_MARKED" ? "Not Marked" : (status == "ABSENT" ? "—" : "09:00 AM"))}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  'Out: ${checkOutTime != null ? DateFormat('hh:mm a').format(checkOutTime) : (status == "NOT_MARKED" || status == "ABSENT" ? "—" : "Active")}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (status != 'NOT_MARKED')
                Text(
                  '${workingHours.toStringAsFixed(1)} hrs',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primary),
                tooltip: 'More Details / Notes',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _showFullEditModal(existingRecord: existingRecord, worker: worker),
              ),
            ],
          ),

          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AttendanceInlineDropdown extends StatelessWidget {
  final String status;
  final Function(String newStatus) onStatusChanged;

  const _AttendanceInlineDropdown({
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String display;

    switch (status.toUpperCase()) {
      case 'PRESENT':
        bg = AppColors.success.withOpacity(0.12);
        fg = AppColors.success;
        display = 'PRESENT';
        break;
      case 'LATE':
        bg = AppColors.warning.withOpacity(0.15);
        fg = AppColors.warning;
        display = 'LATE';
        break;
      case 'HALF_DAY':
        bg = Colors.amber.shade700.withOpacity(0.15);
        fg = Colors.amber.shade800;
        display = 'HALF DAY';
        break;
      case 'ABSENT':
        bg = AppColors.error.withOpacity(0.12);
        fg = AppColors.error;
        display = 'ABSENT';
        break;
      case 'NOT_MARKED':
      default:
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey.shade700;
        display = 'MARK STATUS';
        break;
    }

    return PopupMenuButton<String>(
      tooltip: 'Change Attendance Status',
      onSelected: onStatusChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        _buildPopupItem('PRESENT', 'PRESENT', Icons.check_circle_rounded, AppColors.success),
        _buildPopupItem('LATE', 'LATE', Icons.schedule_rounded, AppColors.warning),
        _buildPopupItem('HALF_DAY', 'HALF DAY', Icons.timelapse_rounded, Colors.amber.shade700),
        _buildPopupItem('ABSENT', 'ABSENT', Icons.cancel_rounded, AppColors.error),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(0.5), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              display,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 20, color: fg),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String label, IconData icon, Color color) {
    final isCurrent = status == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? color : null,
              ),
            ),
          ),
          if (isCurrent) Icon(Icons.check, size: 16, color: color),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
