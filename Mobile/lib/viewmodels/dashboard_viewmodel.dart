import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService api;
  DashboardViewModel(this.api);

  Map<String, dynamic>? profile;
  Map<String, dynamic>? stats;
  Map<String, dynamic>? notifications;
  Map<String, dynamic>? tasks;
  bool loading = false;
  String? error;
  int? concurrentMs;
  int? sequentialMs;

  Future<void> loadConcurrent() async {
    loading = true;
    error = null;
    notifyListeners();
    final stopwatch = Stopwatch()..start();
    try {
      final results = await Future.wait([
        api.request('GET', '/dashboard/profile'),
        api.request('GET', '/dashboard/stats'),
        api.request('GET', '/dashboard/notifications'),
        api.request('GET', '/dashboard/task-summary'),
      ]);
      profile = results[0];
      stats = results[1];
      notifications = results[2];
      tasks = results[3];
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      stopwatch.stop();
      concurrentMs = stopwatch.elapsedMilliseconds;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> compare() async {
    final sequentialWatch = Stopwatch()..start();
    await api.request('GET', '/dashboard/profile');
    await api.request('GET', '/dashboard/stats');
    await api.request('GET', '/dashboard/notifications');
    await api.request('GET', '/dashboard/task-summary');
    sequentialWatch.stop();
    sequentialMs = sequentialWatch.elapsedMilliseconds;

    final concurrentWatch = Stopwatch()..start();
    await Future.wait([
      api.request('GET', '/dashboard/profile'),
      api.request('GET', '/dashboard/stats'),
      api.request('GET', '/dashboard/notifications'),
      api.request('GET', '/dashboard/task-summary'),
    ]);
    concurrentWatch.stop();
    concurrentMs = concurrentWatch.elapsedMilliseconds;
    notifyListeners();
  }
}
