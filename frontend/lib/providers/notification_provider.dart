import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiEndpoints.myNotifications);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => NotificationModel.fromJson(item))
                .toList() ??
            [];
        _notifications = list;
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await ApiService.patch('/notifications/$notificationId/read');
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final old = _notifications[index];
        _notifications[index] = NotificationModel(
          id: old.id,
          title: old.title,
          message: old.message,
          type: old.type,
          isRead: true,
          data: old.data,
          createdAt: old.createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final res = await ApiService.patch(ApiEndpoints.markAllNotificationsRead);
      if (res.success) {
        _notifications = _notifications
            .map((n) => NotificationModel(
                  id: n.id,
                  title: n.title,
                  message: n.message,
                  type: n.type,
                  isRead: true,
                  data: n.data,
                  createdAt: n.createdAt,
                ))
            .toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> broadcastNotification({
    required String title,
    required String message,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.broadcastNotification,
        body: {
          'title': title.trim(),
          'message': message.trim(),
          if (department != null && department != 'ALL') 'department': department,
        },
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
      _errorMessage = 'Failed to broadcast notification: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
