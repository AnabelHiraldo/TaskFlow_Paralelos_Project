
import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import '../../repositories/tasks_repository.dart';
import '../../services/api_service.dart';
import '../../viewmodels/tasks_viewmodel.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  late final TasksViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = TasksViewModel(TasksRepository(ApiService()));
    vm.loadTasks();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _showTaskDialog({TaskModel? task}) async {
    final titleController = TextEditingController(
      text: task?.titulo ?? '',
    );
    final descriptionController = TextEditingController(
      text: task?.descripcion ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(task == null ? 'Nueva tarea' : 'Editar tarea'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Escribe el título de la tarea';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      final titulo = titleController.text.trim();
      final descripcion = descriptionController.text.trim();

      final success = task == null
          ? await vm.createTask(titulo, descripcion)
          : await vm.editTask(task, titulo, descripcion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (task == null
                      ? 'Tarea creada correctamente'
                      : 'Tarea actualizada correctamente')
                  : (vm.error ?? 'No se pudo guardar la tarea'),
            ),
          ),
        );
      }
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Deseas eliminar "${task.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await vm.removeTask(task.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Tarea eliminada'
                : (vm.error ?? 'No se pudo eliminar la tarea'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis tareas'),
            actions: [
              IconButton(
                onPressed: vm.loading ? null : vm.loadTasks,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar tareas',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: vm.saving ? null : () => _showTaskDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Nueva tarea'),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (vm.loading && vm.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null && vm.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(vm.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: vm.loadTasks,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Icon(Icons.task_alt, size: 64),
            SizedBox(height: 16),
            Center(child: Text('Todavía no tienes tareas')),
            SizedBox(height: 8),
            Center(child: Text('Pulsa "Nueva tarea" para comenzar')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadTasks,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: vm.tasks.length,
        itemBuilder: (context, index) {
          final task = vm.tasks[index];

          return Card(
            child: ListTile(
              leading: Checkbox(
                value: task.completada,
                onChanged: (value) async {
                  if (value == null) return;

                  final success = await vm.toggleTask(task, value);

                  if (!success && context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                     content: Text(
                     vm.error ?? 'No se pudo actualizar la tarea',
                      ),
                    ),
                 );
               }
                },
              ),
              title: Text(
                task.titulo,
                style: TextStyle(
                  decoration: task.completada
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: Text(
                task.descripcion.isEmpty
                    ? 'Sin descripción'
                    : task.descripcion,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showTaskDialog(task: task);
                  } else if (value == 'delete') {
                    _deleteTask(task);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}