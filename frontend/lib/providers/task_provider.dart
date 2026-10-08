import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/services/api_service.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _myTasks = [];
  List<TaskModel> _allTasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<TaskModel> get myTasks => _myTasks;
  List<TaskModel> get allTasks => _allTasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int get pendingTasksCount => _myTasks.where((t) => !t.isCompleted).length;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchMyTasks({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'ALL') queryParams['status'] = status;

      final res = await ApiService.get(ApiEndpoints.myTasks, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => TaskModel.fromJson(item))
                .toList() ??
            [];
        _myTasks = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllTasks({String? status, String? priority, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'ALL') queryParams['status'] = status;
      if (priority != null && priority != 'ALL') queryParams['priority'] = priority;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final res = await ApiService.get(ApiEndpoints.tasks, queryParams: queryParams);
      if (res.success && res.data != null) {
        final list = (res.data as List<dynamic>?)
                ?.map((item) => TaskModel.fromJson(item))
                .toList() ??
            [];
        _allTasks = list;
      }
    } catch (e) {
      _errorMessage = 'Failed to load all tasks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTaskStatus({
    required String taskId,
    required String status,
    String? completionNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.patch(
        '${ApiEndpoints.tasks}/$taskId/status',
        body: {
          'status': status,
          if (completionNotes != null) 'completionNotes': completionNotes,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        // Refresh local task list
        await fetchMyTasks();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    required String assignedToId,
    String priority = 'MEDIUM',
    DateTime? dueDate,
    String? location,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        ApiEndpoints.tasks,
        body: {
          'title': title,
          'description': description,
          'assignedToId': assignedToId,
          'priority': priority,
          if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
          if (location != null) 'location': location,
        },
      );

      _isLoading = false;
      if (res.success) {
        _successMessage = res.message;
        await fetchAllTasks();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.delete('${ApiEndpoints.tasks}/$taskId');
      _isLoading = false;
      if (res.success) {
        _allTasks.removeWhere((t) => t.id == taskId);
        _successMessage = res.message;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
