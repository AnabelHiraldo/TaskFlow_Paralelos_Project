
import '../models/task_model.dart';
import '../services/api_service.dart';

class TasksRepository {
  final ApiService api;

  TasksRepository(this.api);

  Future<List<TaskModel>> getTasks() async {
    final result = await api.request('GET', '/tasks');

    if (result is! List) {
      throw Exception('La respuesta de tareas no tiene el formato esperado.');
    }

    return result
        .map(
          (item) => TaskModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<TaskModel> createTask({
    required String titulo,
    required String descripcion,
  }) async {
    final result = await api.request(
      'POST',
      '/tasks',
      body: {
        'titulo': titulo,
        'descripcion': descripcion,
        'completada': false,
      },
    );

    return TaskModel.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final result = await api.request(
      'PUT',
      '/tasks/${task.id}',
      body: task.toJson(),
    );

    return TaskModel.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<void> deleteTask(int id) async {
    await api.request('DELETE', '/tasks/$id');
  }
}