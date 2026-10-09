import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../viewmodels/users_viewmodel.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  late final UsersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UsersViewModel(ApiService());
    _viewModel.loadUsers();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _userName(dynamic user) {
    if (user is! Map) return 'Usuario';

    final nombre = user['nombre'] ?? user['username'] ?? '';
    final apellido = user['apellido'] ?? '';

    final fullName = '$nombre $apellido'.trim();

    if (fullName.isNotEmpty) return fullName;

    return 'Usuario ${user['id'] ?? ''}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_viewModel.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _viewModel.error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _viewModel.loadUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_viewModel.users.isEmpty) {
            return RefreshIndicator(
              onRefresh: _viewModel.loadUsers,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.people_outline, size: 56),
                  SizedBox(height: 12),
                  Center(child: Text('No hay usuarios para mostrar.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _viewModel.loadUsers,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _viewModel.users.length,
              itemBuilder: (context, index) {
                final user = _viewModel.users[index];

                final email = user is Map
                    ? user['email']?.toString() ?? 'Sin correo'
                    : 'Sin correo';

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(_userName(user)),
                    subtitle: Text(email),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}