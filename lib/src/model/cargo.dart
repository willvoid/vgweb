class Cargo {
  int? id;
  DateTime? createdAt;
  String cargo;
  String? descripcionCargo;

  Cargo({
    this.id,
    this.createdAt,
    required this.cargo,
    this.descripcionCargo,
  });

  factory Cargo.fromMap(Map<String, dynamic> map) {
    return Cargo(
      id: map['id'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      cargo: map['cargo'] ?? '',
      descripcionCargo: map['descripcion_cargo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'cargo': cargo,
      if (descripcionCargo != null) 'descripcion_cargo': descripcionCargo,
    };
  }
}
