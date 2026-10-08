import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/api_service.dart';
import '../models/leave_model.dart';

class LeaveProvider extends ChangeNotifier {
  List<LeaveModel> _myLeaves = [];
  List<LeaveModel> _allLeaves = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<LeaveModel> get myLeaves => _myLeaves;
  List<LeaveModel> get allLeaves => _allLeaves;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int get pendingApprovalsCount => _allLeaves.where((l) => l.isPending).length;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchMyLeaves() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiEndpoints.myLeaves);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => LeaveModel.fromJson(item))
                .toList() ??
            [];
        _myLeaves = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load leaves: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllLeaves({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'ALL') queryParams['status'] = status;

      final res = await ApiService.get(ApiEndpoints.allLeaves, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => LeaveModel.fromJson(item))
                .toList() ??
            [];
        _allLeaves = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load all leaves: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.applyLeave,
        body: {
          'leaveType': leaveType,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'reason': reason.trim(),
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchMyLeaves();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to apply leave: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reviewLeave({
    required String leaveId,
    required String status, // 'APPROVED' or 'REJECTED'
    String? adminComment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.patch(
        '${ApiEndpoints.allLeaves}/$leaveId/review',
        body: {
          'status': status,
          if (adminComment != null) 'adminComment': adminComment,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchAllLeaves();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to review leave: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
