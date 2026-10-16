
import 'package:flutter/material.dart';

import '../users/users_view.dart';
import '../tasks/tasks_view.dart';
import '../files/files_view.dart';
import '../notifications/notifications_view.dart';

class DashboardView extends StatelessWidget {
  final VoidCallback onLogout;

  const DashboardView({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
        actions: [
          IconButton(
            onPressed: onLogout,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Bienvenido a TaskFlow!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestiona tus tareas desde un solo lugar.',
            ),
            const SizedBox(height: 24),

            // Módulo de usuarios
            Card(
              child: ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Usuarios'),
                subtitle: const Text(
                  'Consultar y administrar usuarios',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsersView(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Enviar correo'),
                subtitle: const Text('Enviar un correo mediante Pub/Sub'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsView(),
                    ),
                  );
                },
              ),
            ),

            // Módulo de tareas
            Card(
              child: ListTile(
                leading: const Icon(Icons.task_alt),
                title: const Text('Tareas'),
                subtitle: const Text(
                  'Consultar y gestionar tareas',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TasksView(),
                    ),
                  );
                },
              ),
            ),

            // Módulo de archivos
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Archivos'),
                subtitle: const Text(
                  'Subir y administrar archivos',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilesView(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
