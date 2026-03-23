import 'package:myapp/src/model/categoria.dart';

class Producto {
  int? id;
  String nombre;
  String descripcion;
  int precio;
  int cuotas;
  String img;
  int categoria;
  String desc2;
  int? stock;
  List<String>? imagenesAdicionales;
  DateTime? createdAt;
  int? recomendado; // Nueva propiedad (0 = no recomendado, 1 = recomendado)

  Producto({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.img,
    required this.cuotas,
    required this.categoria,
    required this.desc2,
    this.stock,
    this.imagenesAdicionales,
    this.createdAt,
    this.recomendado, // Agregado al constructor
  });

  //Map -> Producto
  factory Producto.fromMap(Map<String, dynamic> map) {
    print('Procesando producto: ${map['nombre']}');
    
    // Procesar imágenes adicionales
    List<String>? imagenes;
    if (map['imagenes'] != null) {
      print('Campo imagenes encontrado: ${map['imagenes']}');
      try {
        imagenes = (map['imagenes'] as List)
            .map((img) {
              print('   Procesando imagen: $img');
              return img['url_img'] as String;
            })
            .toList();
        print('✅ Se procesaron ${imagenes.length} imágenes adicionales');
      } catch (e) {
        print('❌ Error al procesar imágenes: $e');
      }
    } else {
      print('⚠️ No se encontró el campo imagenes en el map');
    }

    // Procesar created_at
    DateTime? createdAt;
    if (map['created_at'] != null) {
      try {
        createdAt = DateTime.parse(map['created_at'].toString());
        print('✅ created_at procesado: $createdAt');
      } catch (e) {
        print('❌ Error al procesar created_at: $e');
      }
    }
    
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precio: map['precio'],
      img: map['url_img'],
      cuotas: map['cuotas'],
      categoria: map['id_categoria'],
      desc2: map['desc2'],
      stock: map['stock'],
      imagenesAdicionales: imagenes,
      createdAt: createdAt,
      recomendado: map['recomendado'] as int?, // Procesar recomendado
    );
  }

  //Producto -> Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'img': img,
      'cuotas': cuotas,
      'categoria': categoria,
      'desc2': desc2,
      'stock': stock,
      'created_at': createdAt?.toIso8601String(),
      'recomendado': recomendado,
      // No incluimos imagenesAdicionales porque es solo para lectura
    };
  }

  // Método helper para obtener todas las imágenes del producto
  List<String> obtenerTodasLasImagenes() {
    List<String> todasLasImagenes = [img]; // Imagen principal primero
    
    print('Obteniendo todas las imágenes del producto: $nombre');
    
    if (imagenesAdicionales != null && imagenesAdicionales!.isNotEmpty) {
      print('   Imágenes adicionales encontradas: ${imagenesAdicionales!.length}');
      for (var i = 0; i < imagenesAdicionales!.length; i++) {
        print('   Imagen ${i + 1}: ${imagenesAdicionales![i]}');
      }
      todasLasImagenes.addAll(imagenesAdicionales!);
    } else {
      print('No hay imágenes adicionales');
    }
    
    print('   Total de imágenes: ${todasLasImagenes.length}');
    return todasLasImagenes;
  }

  // Método helper para verificar si es un producto nuevo (últimos 30 días)
  bool esNuevo() {
    if (createdAt == null) return false;
    final diasDesdeCreacion = DateTime.now().difference(createdAt!).inDays;
    return diasDesdeCreacion <= 30;
  }

  // Método helper para verificar si es recomendado
  bool esRecomendado() {
    return recomendado == 1;
  }

  // Método helper para obtener el tiempo desde la creación
  String obtenerTiempoDesdeCreacion() {
    if (createdAt == null) return 'Fecha desconocida';
    
    final diferencia = DateTime.now().difference(createdAt!);
    
    if (diferencia.inDays > 365) {
      final anios = (diferencia.inDays / 365).floor();
      return 'Hace $anios ${anios == 1 ? 'año' : 'años'}';
    } else if (diferencia.inDays > 30) {
      final meses = (diferencia.inDays / 30).floor();
      return 'Hace $meses ${meses == 1 ? 'mes' : 'meses'}';
    } else if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} ${diferencia.inDays == 1 ? 'día' : 'días'}';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} ${diferencia.inHours == 1 ? 'hora' : 'horas'}';
    } else {
      return 'Hace unos minutos';
    }
  }
}