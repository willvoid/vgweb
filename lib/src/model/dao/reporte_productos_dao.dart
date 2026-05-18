import 'package:supabase_flutter/supabase_flutter.dart';

/// DAO para consultar la vista v_productos_por_categoria de Supabase
class ReporteProductosDao {
  final _client = Supabase.instance.client;

  /// Obtiene todos los productos agrupados por categoría desde la vista SQL
  Future<List<Map<String, dynamic>>> obtenerProductosPorCategoria() async {
    final response = await _client
        .from('v_productos_por_categoria')
        .select()
        .order('categoria_nombre', ascending: true)
        .order('producto_nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}
