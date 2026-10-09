import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../repositories/user_repository.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = UserRepository(ApiService());
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: FutureBuilder(
        future: repo.list(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
          final users = snapshot.data ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) => ListTile(
              title: Text('${users[i].nombre} ${users[i].apellido}'),
              subtitle: Text(users[i].email),
            ),
          );
        },
      ),
    );
  }
}
