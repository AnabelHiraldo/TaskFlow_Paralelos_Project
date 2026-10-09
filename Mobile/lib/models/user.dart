class User {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    nombre: json['nombre'],
    apellido: json['apellido'],
    email: json['email'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
