import 'package:myapp/src/model/imagen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ImagenCrud {
  /// Inserta una nueva imagen vinculada a un producto
  Future<Imagen?> crearImagen(Imagen imagen) async {
    try {
      final response = await supabase
          .from('imagenes')
          .insert(imagen.toMap())
          .select()
          .single();

      return Imagen.fromMap(response);
    } catch (e) {
      print('Error al crear imagen: $e');
      return null;
    }
  }

  /// Obtiene todas las imágenes de un producto
  Future<List<Imagen>> leerImagenesPorProducto(int idProducto) async {
    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('imagenes')
          .select()
          .eq('id_producto', idProducto)
          .order('created_at', ascending: true);

      if (data.isEmpty) return [];

      return data.map((mapa) => Imagen.fromMap(mapa)).toList();
    } catch (e) {
      print('Error al leer imágenes del producto $idProducto: $e');
      return [];
    }
  }

  /// Elimina una imagen por su id
  Future<bool> eliminarImagen(int id) async {
    try {
      await supabase.from('imagenes').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error al eliminar imagen $id: $e');
      return false;
    }
  }
}
