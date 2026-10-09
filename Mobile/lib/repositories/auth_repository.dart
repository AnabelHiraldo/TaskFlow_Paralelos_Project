import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService api;

  AuthRepository(this.api);

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    final result = await api.request(
      'POST',
      '/auth/register',
      body: {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
      },
    );

    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final data = await api.login(email, password);
    final token = data['access_token'] ?? data['token'];

    if (token == null) {
      throw Exception('El servidor no devolvió el token de acceso.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token.toString());

    return Map<String, dynamic>.from(data);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }
}