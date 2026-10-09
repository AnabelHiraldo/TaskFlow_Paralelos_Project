
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class UsersViewModel extends ChangeNotifier {
  final ApiService api;

  UsersViewModel(this.api);

  List<dynamic> users = [];
  bool loading = false;
  String? error;

  Future<void> loadUsers() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await api.request('GET', '/users');

      if (result is List) {
        users = result;
      } else if (result is Map && result['users'] is List) {
        users = result['users'];
      } else {
        users = [];
        error = 'El servidor devolvió un formato de usuarios inesperado.';
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
