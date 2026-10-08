import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/api_service.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  List<ExpenseModel> _myExpenses = [];
  List<ExpenseModel> _allExpenses = [];
  double _myTotalAmount = 0.0;
  double _allTotalAmount = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<ExpenseModel> get myExpenses => _myExpenses;
  List<ExpenseModel> get allExpenses => _allExpenses;
  double get myTotalAmount => _myTotalAmount;
  double get allTotalAmount => _allTotalAmount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchMyExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiEndpoints.myExpenses);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => ExpenseModel.fromJson(item))
                .toList() ??
            [];
        _myExpenses = list;
        _myTotalAmount = (res.data is Map && res.data['totalAmount'] != null)
            ? (res.data['totalAmount'] as num).toDouble()
            : _myExpenses.fold(0.0, (sum, e) => sum + e.amount);
      }
    } catch (e) {
      _errorMessage = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllExpenses({String? status, String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'ALL') queryParams['status'] = status;
      if (category != null && category != 'ALL') queryParams['category'] = category;

      final res = await ApiService.get(ApiEndpoints.allExpenses, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => ExpenseModel.fromJson(item))
                .toList() ??
            [];
        _allExpenses = list;
        _allTotalAmount = _allExpenses.fold(0.0, (sum, e) => sum + e.amount);
      }
    } catch (e) {
      _errorMessage = 'Failed to load all expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitExpense({
    required String category,
    required double amount,
    required String description,
    String? receiptUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.submitExpense,
        body: {
          'category': category,
          'amount': amount,
          'description': description.trim(),
          if (receiptUrl != null) 'receiptUrl': receiptUrl,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchMyExpenses();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to submit expense: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reviewExpense({
    required String expenseId,
    required String status,
    String? adminComment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.patch(
        '${ApiEndpoints.allExpenses}/$expenseId/review',
        body: {
          'status': status,
          if (adminComment != null) 'adminComment': adminComment,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchAllExpenses();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to review expense: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
