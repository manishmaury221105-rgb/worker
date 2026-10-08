import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token != null) {
        final res = await ApiService.get(ApiEndpoints.me);
        if (res.success && res.data != null) {
          _currentUser = UserModel.fromJson(res.data);
          _isAuthenticated = true;
        } else {
          await StorageService.clearAll();
          _isAuthenticated = false;
        }
      }
    } catch (_) {
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.login,
        body: {'identifier': identifier.trim(), 'password': password},
        requireAuth: false,
      );

      if (res.success && res.data != null) {
        final token = res.data['token'];
        final userData = res.data['user'];

        await StorageService.saveToken(token);
        await StorageService.saveUser(userData);

        _currentUser = UserModel.fromJson(userData);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await ApiService.get(ApiEndpoints.me);
      if (res.success && res.data != null) {
        _currentUser = UserModel.fromJson(res.data);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? emergencyContact,
    String? bankAccount,
    String? upiId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.put(
        ApiEndpoints.profile,
        body: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (emergencyContact != null) 'emergencyContact': emergencyContact,
          if (bankAccount != null) 'bankAccount': bankAccount,
          if (upiId != null) 'upiId': upiId,
        },
      );

      if (res.success && res.data != null) {
        _currentUser = UserModel.fromJson(res.data);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.changePassword,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      _isLoading = false;
      if (!res.success) {
        _errorMessage = res.message;
      }
      notifyListeners();
      return res.success;
    } catch (e) {
      _errorMessage = 'Failed to change password: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
