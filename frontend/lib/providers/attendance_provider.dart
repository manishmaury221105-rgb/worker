import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/api_service.dart';
import '../core/services/location_service.dart';
import '../models/attendance_model.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _history = [];
  List<AttendanceModel> _allAttendance = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = false;
  bool _isCheckingAction = false;
  bool _isDateLocked = false;
  bool _isTodayLocked = false;
  String? _errorMessage;
  String? _successMessage;

  AttendanceModel? get todayAttendance => _todayAttendance;
  List<AttendanceModel> get history => _history;
  List<AttendanceModel> get allAttendance => _allAttendance;
  Map<String, dynamic>? get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isCheckingAction => _isCheckingAction;
  bool get isDateLocked => _isDateLocked;
  bool get isTodayLocked => _isTodayLocked;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get isCheckedInToday => _todayAttendance?.isCheckedIn ?? false;
  bool get isCheckedOutToday => _todayAttendance?.isCheckedOut ?? false;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchLockStatus({String? date}) async {
    try {
      final res = await ApiService.get(
        ApiEndpoints.attendanceLockStatus,
        queryParams: date != null ? {'date': date} : null,
      );
      if (res.success && res.data != null) {
        final locked = res.data['isLocked'] == true;
        if (date == null) {
          _isTodayLocked = locked;
        }
        _isDateLocked = locked;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> toggleAttendanceLock({required String date, required bool isLocked}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.attendanceToggleLock,
        body: {'date': date, 'isLocked': isLocked},
      );

      _isLoading = false;
      if (res.success) {
        _isDateLocked = isLocked;
        _successMessage = res.message;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update attendance lock: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchTodayAttendance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiEndpoints.todayAttendance);
      if (res.success && res.data != null) {
        if (res.data is Map<String, dynamic>) {
          _isTodayLocked = res.data['isLocked'] == true;
          final attData = res.data['data'] ?? res.data;
          if (attData is Map<String, dynamic> && attData.containsKey('userId')) {
            _todayAttendance = AttendanceModel.fromJson(attData);
          } else {
            _todayAttendance = null;
          }
        } else {
          _todayAttendance = null;
        }
      } else {
        _todayAttendance = null;
      }
      await fetchLockStatus();
    } catch (e) {
      _errorMessage = 'Failed to load today attendance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selfMarkAttendance({required String status, String? date}) async {
    _isCheckingAction = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.selfMarkAttendance,
        body: {
          'status': status,
          if (date != null) 'date': date,
        },
      );

      _isCheckingAction = false;
      if (res.success && res.data != null) {
        _todayAttendance = AttendanceModel.fromJson(res.data);
        _successMessage = res.message;
        notifyListeners();
        await fetchMyHistory();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to mark attendance: $e';
      _isCheckingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkIn({String? notes}) async {
    _isCheckingAction = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Get GPS coordinates
      final loc = await LocationService.getCurrentLocation();

      // 2. Send Check-in API request
      final res = await ApiService.post(
        ApiEndpoints.checkIn,
        body: {
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'address': loc.address,
          'notes': notes,
        },
      );

      if (res.success && res.data != null) {
        _todayAttendance = AttendanceModel.fromJson(res.data);
        _successMessage = res.message;
        _isCheckingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        _isCheckingAction = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Check-in failed: $e';
      _isCheckingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut({String? notes}) async {
    _isCheckingAction = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final loc = await LocationService.getCurrentLocation();

      final res = await ApiService.post(
        ApiEndpoints.checkOut,
        body: {
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'address': loc.address,
          'notes': notes,
        },
      );

      if (res.success && res.data != null) {
        _todayAttendance = AttendanceModel.fromJson(res.data);
        _successMessage = res.message;
        _isCheckingAction = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        _isCheckingAction = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Check-out failed: $e';
      _isCheckingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyHistory({int? month, int? year}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final res = await ApiService.get(ApiEndpoints.myAttendanceHistory, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => AttendanceModel.fromJson(item))
                .toList() ??
            [];
        _history = list;
        _summary = res.data is Map ? res.data['summary'] : null;
      }
    } catch (e) {
      _errorMessage = 'Failed to load history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchWorkerMonthlyAttendance({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final res = await ApiService.get(
        ApiEndpoints.workerMonthlyAttendance,
        queryParams: {
          'userId': userId,
          'month': month,
          'year': year,
        },
      );
      if (res.success && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<void> fetchAllAttendance({String? date, String? status, String? department}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;
      if (status != null && status != 'ALL') queryParams['status'] = status;
      if (department != null && department != 'ALL') queryParams['department'] = department;

      final res = await ApiService.get(ApiEndpoints.allAttendance, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => AttendanceModel.fromJson(item))
                .toList() ??
            [];
        _allAttendance = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load attendance records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> manualMarkAttendance({
    required String userId,
    required String date,
    required String status,
    double workingHours = 8.0,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'userId': userId,
        'date': date,
        'status': status,
        'workingHours': workingHours,
        'notes': notes,
      };
      if (checkInTime != null) {
        body['checkInTime'] = checkInTime.toIso8601String();
      }
      if (checkOutTime != null) {
        body['checkOutTime'] = checkOutTime.toIso8601String();
      }

      final res = await ApiService.post(
        ApiEndpoints.manualAttendance,
        body: body,
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to mark attendance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
