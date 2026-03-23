class Categoria {
  int? id;
  late String descripcion;
  String nombre;
  String img;

  Categoria({
    this.id, 
    required this.descripcion,
    required this.nombre,
    required this.img,
  });


  //Map -> Note
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      descripcion: map['descripcion'], 
      nombre: map['nombre'], 
      img: map['url_img'],
    );
  }

  //Note -> Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'nombre': nombre,
      'img': img,
    };
  }
}
