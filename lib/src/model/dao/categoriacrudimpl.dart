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
}