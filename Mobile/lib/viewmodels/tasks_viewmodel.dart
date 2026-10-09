
import 'package:flutter/foundation.dart';

import '../models/task_model.dart';
import '../repositories/tasks_repository.dart';

class TasksViewModel extends ChangeNotifier {
  final TasksRepository repository;

  TasksViewModel(this.repository);

  List<TaskModel> tasks = [];
  bool loading = false;
  bool saving = false;
  String? error;

  Future<void> loadTasks() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      tasks = await repository.getTasks();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask(
    String titulo,
    String descripcion,
  ) async {
    saving = true;
    error = null;
    notifyListeners();

    try {
      final task = await repository.createTask(
        titulo: titulo,
        descripcion: descripcion,
      );

      tasks.insert(0, task);
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> toggleTask(TaskModel task, bool completada) async {
    final updatedTask = TaskModel(
      id: task.id,
      titulo: task.titulo,
      descripcion: task.descripcion,
      completada: completada,
      createdAt: task.createdAt,
    );

    error = null;

    try {
      final savedTask = await repository.updateTask(updatedTask);

      final index = tasks.indexWhere((item) => item.id == task.id);

      if (index != -1) {
        tasks[index] = savedTask;
      }

      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> editTask(
    TaskModel task,
    String titulo,
    String descripcion,
  ) async {
    final updatedTask = TaskModel(
      id: task.id,
      titulo: titulo,
      descripcion: descripcion,
      completada: task.completada,
      createdAt: task.createdAt,
    );

    error = null;

    try {
      final savedTask = await repository.updateTask(updatedTask);

      final index = tasks.indexWhere((item) => item.id == task.id);

      if (index != -1) {
        tasks[index] = savedTask;
      }

      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeTask(int id) async {
    error = null;

    try {
      await repository.deleteTask(id);
      tasks.removeWhere((task) => task.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}