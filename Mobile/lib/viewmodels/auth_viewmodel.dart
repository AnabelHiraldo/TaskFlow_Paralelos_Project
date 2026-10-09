
import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository(ApiService());

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  bool isAuthenticated = false;

  Future<bool> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      await _repository.register(
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
      );

      successMessage = 'Usuario registrado correctamente.';
      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      successMessage = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
     
     await _repository.login(email, password);

      isAuthenticated = true;
      successMessage = 'Inicio de sesión correcto.';
      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      successMessage = null;
      isAuthenticated = false;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    isAuthenticated = false;
    successMessage = null;
    errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}

