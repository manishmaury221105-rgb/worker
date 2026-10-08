import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/api_service.dart';
import '../models/dashboard_stats_model.dart';
import '../models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  DashboardStatsModel? _dashboardStats;
  List<UserModel> _workers = [];
  List<String> _departments = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  DashboardStatsModel? get dashboardStats => _dashboardStats;
  List<UserModel> get workers => _workers;
  List<String> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiEndpoints.dashboardReport);
      if (res.success && res.data != null) {
        _dashboardStats = DashboardStatsModel.fromJson(res.data);
      }
    } catch (e) {
      _errorMessage = 'Failed to load dashboard stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDepartments() async {
    try {
      final res = await ApiService.get(ApiEndpoints.departments);
      if (res.success && res.data != null) {
        _departments = List<String>.from(res.data);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchWorkers({String? search, String? department, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (department != null && department != 'ALL') queryParams['department'] = department;
      if (status != null && status != 'ALL') queryParams['status'] = status;

      final res = await ApiService.get(ApiEndpoints.workers, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => UserModel.fromJson(item))
                .toList() ??
            [];
        _workers = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load workers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createWorker({
    required String name,
    required String email,
    required String phone,
    String password = 'password123',
    String role = 'WORKER',
    String department = 'General',
    String designation = 'Worker',
    double monthlySalary = 20000,
    double hourlyRate = 100,
    String? address,
    String? emergencyContact,
    String? bankAccount,
    String? upiId,
    String? aadhaarNumber,
    String? aadhaarFrontUrl,
    String? aadhaarBackUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.workers,
        body: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'password': password,
          'role': role,
          'department': department,
          'designation': designation,
          'monthlySalary': monthlySalary,
          'hourlyRate': hourlyRate,
          'address': address,
          'emergencyContact': emergencyContact,
          'bankAccount': bankAccount,
          'upiId': upiId,
          if (aadhaarNumber != null) 'aadhaarNumber': aadhaarNumber,
          if (aadhaarFrontUrl != null) 'aadhaarFrontUrl': aadhaarFrontUrl,
          if (aadhaarBackUrl != null) 'aadhaarBackUrl': aadhaarBackUrl,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchWorkers();
        await fetchDashboardStats();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create worker: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWorker({
    required String workerId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? department,
    String? designation,
    double? monthlySalary,
    double? hourlyRate,
    String? status,
    String? address,
    String? emergencyContact,
    String? bankAccount,
    String? upiId,
    String? aadhaarNumber,
    String? aadhaarFrontUrl,
    String? aadhaarBackUrl,
    String? password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.put(
        '${ApiEndpoints.workers}/$workerId',
        body: {
          if (name != null) 'name': name.trim(),
          if (email != null) 'email': email.trim().toLowerCase(),
          if (phone != null) 'phone': phone.trim(),
          if (role != null) 'role': role,
          if (department != null) 'department': department,
          if (designation != null) 'designation': designation,
          if (monthlySalary != null) 'monthlySalary': monthlySalary,
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
          if (status != null) 'status': status,
          if (address != null) 'address': address,
          if (emergencyContact != null) 'emergencyContact': emergencyContact,
          if (bankAccount != null) 'bankAccount': bankAccount,
          if (upiId != null) 'upiId': upiId,
          if (aadhaarNumber != null) 'aadhaarNumber': aadhaarNumber,
          if (aadhaarFrontUrl != null) 'aadhaarFrontUrl': aadhaarFrontUrl,
          if (aadhaarBackUrl != null) 'aadhaarBackUrl': aadhaarBackUrl,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchWorkers();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update worker: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorker(String workerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.delete('${ApiEndpoints.workers}/$workerId');
      _isLoading = false;
      if (res.success) {
        _workers.removeWhere((w) => w.id == workerId);
        _successMessage = res.message;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete worker: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
