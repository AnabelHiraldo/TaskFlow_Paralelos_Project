import '../models/user.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService api;
  UserRepository(this.api);

  Future<User> me() async {
    final data = await api.request('GET', '/users/me');
    return User.fromJson(data);
  }

  Future<List<User>> list() async {
    final data = await api.request('GET', '/users');
    return (data as List).map((e) => User.fromJson(e)).toList();
  }

  Future<User> updateMe(String nombre, String apellido, String email) async {
    final data = await api.request('PUT', '/users/0', body: {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
    });
    return User.fromJson(data);
  }
}
