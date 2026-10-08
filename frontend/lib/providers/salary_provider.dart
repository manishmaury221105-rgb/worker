import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/api_service.dart';
import '../models/salary_model.dart';

class SalaryProvider extends ChangeNotifier {
  List<SalaryRecordModel> _mySalaryRecords = [];
  List<SalaryRecordModel> _allSalaryRecords = [];
  List<SalaryAdvanceModel> _myAdvances = [];
  List<SalaryAdvanceModel> _allAdvances = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<SalaryRecordModel> get mySalaryRecords => _mySalaryRecords;
  List<SalaryRecordModel> get allSalaryRecords => _allSalaryRecords;
  List<SalaryAdvanceModel> get myAdvances => _myAdvances;
  List<SalaryAdvanceModel> get allAdvances => _allAdvances;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  double get totalPendingPayout => _allSalaryRecords
      .where((s) => s.status != 'PAID')
      .fold(0.0, (sum, s) => sum + s.netSalary);

  double get totalPaidPayout => _allSalaryRecords
      .where((s) => s.status == 'PAID')
      .fold(0.0, (sum, s) => sum + s.netSalary);

  double get totalSalaryAmount => _allSalaryRecords
      .fold(0.0, (sum, s) => sum + s.netSalary);

  int get pendingPayoutCount => _allSalaryRecords
      .where((s) => s.status != 'PAID')
      .length;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchMySalaryRecords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiEndpoints.mySalaryRecords);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => SalaryRecordModel.fromJson(item))
                .toList() ??
            [];
        _mySalaryRecords = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load salary records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyAdvances() async {
    try {
      final res = await ApiService.get(ApiEndpoints.myAdvances);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => SalaryAdvanceModel.fromJson(item))
                .toList() ??
            [];
        _myAdvances = list;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> requestAdvance({required double amount, required String reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.requestAdvance,
        body: {'amount': amount, 'reason': reason.trim()},
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchMyAdvances();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to request advance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAllSalaryRecords({int? month, int? year, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;
      if (status != null && status != 'ALL') queryParams['status'] = status;

      final res = await ApiService.get(ApiEndpoints.allSalaryRecords, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => SalaryRecordModel.fromJson(item))
                .toList() ??
            [];
        _allSalaryRecords = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load salary records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllAdvances({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'ALL') queryParams['status'] = status;

      final res = await ApiService.get(ApiEndpoints.allAdvances, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => SalaryAdvanceModel.fromJson(item))
                .toList() ??
            [];
        _allAdvances = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load advances: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generatePayslip({
    required String userId,
    required int month,
    required int year,
    double? presentDays,
    double bonus = 0,
    double deductions = 0,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.generatePayslip,
        body: {
          'userId': userId,
          'month': month,
          'year': year,
          if (presentDays != null) 'presentDays': presentDays,
          'bonus': bonus,
          'deductions': deductions,
          'notes': notes,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchAllSalaryRecords(month: month, year: year);
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to generate payslip: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSalaryStatus({
    required String recordId,
    required String status,
    String paymentMethod = 'Bank Transfer',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.patch(
        '/salary/records/$recordId/status',
        body: {'status': status, 'paymentMethod': paymentMethod},
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchAllSalaryRecords();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update salary status: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reviewAdvance({
    required String advanceId,
    required String status,
    String? adminComment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.patch(
        '/salary/advance/$advanceId/review',
        body: {
          'status': status,
          if (adminComment != null) 'adminComment': adminComment,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchAllAdvances();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to review advance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
