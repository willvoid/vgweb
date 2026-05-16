class Imagen {
  int? id;
  DateTime? createdAt;
  String urlImg;
  int idProducto;

  Imagen({
    this.id,
    this.createdAt,
    required this.urlImg,
    required this.idProducto,
  });

  factory Imagen.fromMap(Map<String, dynamic> map) {
    return Imagen(
      id: map['id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      urlImg: map['url_img'] ?? '',
      idProducto: map['id_producto'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'url_img': urlImg,
      'id_producto': idProducto,
    };
  }
}
