class Usuario {
  String id;
  DateTime? createdAt;
  String? nombre;
  String? usuario;
  int? fkCargo;
  String? telefono;

  Usuario({
    required this.id,
    this.createdAt,
    this.nombre,
    this.usuario,
    this.fkCargo,
    this.telefono,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      nombre: map['nombre'],
      usuario: map['usuario'],
      fkCargo: map['fk_cargo'],
      telefono: map['telefono'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (nombre != null) 'nombre': nombre,
      if (usuario != null) 'usuario': usuario,
      if (fkCargo != null) 'fk_cargo': fkCargo,
      if (telefono != null) 'telefono': telefono,
    };
  }
}
