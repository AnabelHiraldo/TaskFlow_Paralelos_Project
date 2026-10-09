import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Registrar un usuario nuevo.
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    final result = await _api.request(
      'POST',
      '/auth/register',
      body: {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
      },
    );

    return Map<String, dynamic>.from(result as Map);
  }

  // Iniciar sesión y guardar el JWT.
  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final result = await _api.login(email, password);

    final token = result['access_token'] ?? result['token'];

    if (token == null) {
      throw Exception('El servidor no devolvió el token de acceso.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token.toString());

    return Map<String, dynamic>.from(result);
  }

  // Cerrar sesión.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Comprobar si existe un token guardado.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }
}

