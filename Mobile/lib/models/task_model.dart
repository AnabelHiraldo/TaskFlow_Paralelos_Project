
class TaskModel {
  final int id;
  final String titulo;
  final String descripcion;
  final bool completada;
  final DateTime? createdAt;

  TaskModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.completada,
    this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      completada: json['completada'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'completada': completada,
    };
  }
}