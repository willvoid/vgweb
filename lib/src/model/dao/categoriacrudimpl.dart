import 'package:myapp/src/model/categoria.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CategoriaCrud {
  // Esta función asincrónica se conectará a Supabase y devolverá una lista de Categorias.
  Future<List<Categoria>> leerCategorias() async {
    try {
      // 1. Realiza la consulta a tu tabla 'categorias'.
      //    El método .select() sin filtros obtiene todos los registros.
      final List<Map<String, dynamic>> data = await supabase.from('categorias').select();

      // 2. Verifica si la respuesta no está vacía.
      if (data.isEmpty) {
        // Si no hay categorías, devuelve una lista vacía.
        return [];
      }

      // 3. Convierte cada mapa de la respuesta en un objeto Categoria.
      //    Usamos el factory `Categoria.fromMap` que definimos.
      final List<Categoria> categorias = data.map((mapa) => Categoria.fromMap(mapa)).toList();
      
      return categorias;

    } catch (e) {
      // Es una buena práctica manejar posibles errores.
      print('Error al leer las categorías: $e');
      // Puedes lanzar el error o devolver una lista vacía.
      return [];
    }
  }

  /// Crea una nueva categoría en la base de datos
  Future<Categoria?> crearCategoria(Categoria categoria) async {
    try {
      final response = await supabase
          .from('categorias')
          .insert({
            'nombre': categoria.nombre,
            'descripcion': categoria.descripcion,
            'url_img': categoria.img,
          })
          .select()
          .single();

      return Categoria.fromMap(response);
    } catch (e) {
      print('Error al crear categoría: $e');
      return null;
    }
  }

  /// Actualiza una categoría existente
  Future<bool> actualizarCategoria(Categoria categoria) async {
    try {
      await supabase
          .from('categorias')
          .update({
            'nombre': categoria.nombre,
            'descripcion': categoria.descripcion,
            'url_img': categoria.img,
          })
          .eq('id', categoria.id!);

      return true;
    } catch (e) {
      print('Error al actualizar categoría: $e');
      return false;
    }
  }

  /// Elimina una categoría por su id
  Future<bool> eliminarCategoria(int id) async {
    try {
      await supabase.from('categorias').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error al eliminar categoría $id: $e');
      return false;
    }
  }
}