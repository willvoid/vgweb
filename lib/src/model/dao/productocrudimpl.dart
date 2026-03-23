import 'package:myapp/src/model/producto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Productocrudimpl {
  
  Future<List<Producto>> leerProductos() async {
    try {
      // Realizar la consulta - Supabase devuelve List<Map<String, dynamic>> directamente
      final response = await supabase.from('producto').select();
      
      // Verificar si la respuesta es nula o vacía
      if (response == null || response.isEmpty) {
        print('No se encontraron productos');
        return [];
      }

      // La respuesta ya es una lista, solo necesitamos asegurar el tipo
      final data = response as List;

      // Convertir cada elemento a Producto, filtrando los que fallen
      final List<Producto> productos = [];
      for (var item in data) {
        try {
          // Convertir el item a Map<String, dynamic>
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('Error al convertir producto: $e');
          print('Tipo del item: ${item.runtimeType}');
          print('Datos del producto problemático: $item');
          // Continuar con el siguiente producto en lugar de fallar todo
        }
      }

      print('Se cargaron ${productos.length} productos exitosamente');
      return productos;

    } on PostgrestException catch (e) {
      print('Error de Supabase: ${e.message}');
      print('Código: ${e.code}');
      print('Detalles: ${e.details}');
      return [];
    } catch (e, stackTrace) {
      print('Error al leer los productos: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Producto>> leerProductosPorCategoria(String categoriaId) async {
    try {
      // Realizar la consulta con filtro
      final response = await supabase
          .from('producto')
          .select()
          .eq('id_categoria', categoriaId);
      
      // Verificar si la respuesta es nula o vacía
      if (response == null || response.isEmpty) {
        print('No se encontraron productos para la categoría: $categoriaId');
        return [];
      }

      // La respuesta ya es una lista
      final data = response as List;

      // Convertir cada elemento a Producto
      final List<Producto> productos = [];
      for (var item in data) {
        try {
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('Error al convertir producto: $e');
          print('Tipo del item: ${item.runtimeType}');
          print('Datos del producto problemático: $item');
        }
      }

      print('Se cargaron ${productos.length} productos de la categoría $categoriaId');
      return productos;

    } on PostgrestException catch (e) {
      print('Error de Supabase: ${e.message}');
      print('Código: ${e.code}');
      print('Detalles: ${e.details}');
      return [];
    } catch (e, stackTrace) {
      print('Error al leer los productos por categoria: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Método adicional para leer un solo producto
  Future<Producto?> leerProductoPorId(String productoId) async {
    try {
      final response = await supabase
          .from('producto')
          .select()
          .eq('id', productoId)
          .single();
      
      if (response == null) {
        print('No se encontró el producto con ID: $productoId');
        return null;
      }

      final mapa = response as Map<String, dynamic>;
      return Producto.fromMap(mapa);

    } on PostgrestException catch (e) {
      print('Error de Supabase: ${e.message}');
      return null;
    } catch (e) {
      print('Error al leer el producto: $e');
      return null;
    }
  }

  // Método para buscar productos por nombre, descripción o categoría
  Future<List<Producto>> buscarProductos(String termino) async {
    try {
      print('🔍 Buscando productos con término: $termino');
      
      // Primero: Buscar productos por nombre, descripción o desc2
      final responseProductos = await supabase
          .from('producto')
          .select('*, categorias(id, nombre)')
          .or('nombre.ilike.%$termino%,descripcion.ilike.%$termino%,desc2.ilike.%$termino%');

      // Segundo: Buscar productos por nombre de categoría
      final responseCategorias = await supabase
          .from('producto')
          .select('*, categorias!inner(id, nombre)')
          .ilike('categorias.nombre', '%$termino%');

      // Combinar resultados evitando duplicados
      final Set<String> productosIds = {};
      final List<Producto> productos = [];

      // Procesar productos encontrados por nombre/descripción
      if (responseProductos != null && responseProductos.isNotEmpty) {
        final data = responseProductos as List;
        for (var item in data) {
          try {
            final mapa = item as Map<String, dynamic>;
            final productoId = mapa['id'].toString();
            
            if (!productosIds.contains(productoId)) {
              productosIds.add(productoId);
              productos.add(Producto.fromMap(mapa));
              //print('Producto encontrado (por producto): ${mapa['nombre']}');
            }
          } catch (e) {
            print('Error al convertir producto: $e');
          }
        }
      }

      // Procesar productos encontrados por categoría
      if (responseCategorias != null && responseCategorias.isNotEmpty) {
        final data = responseCategorias as List;
        for (var item in data) {
          try {
            final mapa = item as Map<String, dynamic>;
            final productoId = mapa['id'].toString();
            
            if (!productosIds.contains(productoId)) {
              productosIds.add(productoId);
              productos.add(Producto.fromMap(mapa));
              //print('Producto encontrado (por categoría): ${mapa['nombre']}');
              if (mapa['categorias'] != null) {
                print('   Categoría: ${mapa['categorias']['nombre']}');
              }
            }
          } catch (e) {
            print('Error al convertir producto: $e');
          }
        }
      }

      //print('Se encontraron ${productos.length} productos en total');
      return productos;

    } on PostgrestException catch (e) {
      print('Error de Supabase en búsqueda: ${e.message}');
      print('Código: ${e.code}');
      print('Detalles: ${e.details}');
      print('Hint: ${e.hint}');
      return [];
    } catch (e, stackTrace) {
      print(' Error al buscar productos: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Método de búsqueda simple (sin join, solo en campos de producto)
  Future<List<Producto>> buscarProductosSimple(String termino) async {
    try {
      print('🔍 Buscando productos (simple) con término: $termino');
      
      // Buscar solo en nombre, descripcion y desc2
      final response = await supabase
          .from('producto')
          .select()
          .or('nombre.ilike.%$termino%,descripcion.ilike.%$termino%,desc2.ilike.%$termino%');

      if (response == null || response.isEmpty) {
        print('No se encontraron productos con el término: $termino');
        return [];
      }

      final data = response as List;

      final List<Producto> productos = [];
      for (var item in data) {
        try {
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('Error al convertir producto en búsqueda: $e');
        }
      }

      return productos;

    } on PostgrestException catch (e) {
      print('Error de Supabase en búsqueda: ${e.message}');
      print('Código: ${e.code}');
      print('Detalles: ${e.details}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error al buscar productos: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Método alternativo de búsqueda usando textSearch (si tu base de datos lo soporta)
  Future<List<Producto>> buscarProductosTextSearch(String termino) async {
    try {
      print('🔍 Buscando productos (text search) con término: $termino');
      
      final response = await supabase
          .from('producto')
          .select()
          .textSearch('nombre', termino, config: 'spanish');

      if (response == null || response.isEmpty) {
        print('No se encontraron productos con el término: $termino');
        return [];
      }

      final data = response as List;

      final List<Producto> productos = [];
      for (var item in data) {
        try {
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('Error al convertir producto en búsqueda: $e');
        }
      }

      print('Se encontraron ${productos.length} productos');
      return productos;

    } catch (e) {
      print('Error al buscar productos (text search): $e');
      return [];
    }
  }

// Reemplaza este método en tu Productocrudimpl

Future<Producto?> obtenerProductoConImagenes(int idProducto) async {
  try {
    print('Consultando producto con ID: $idProducto');
    
    // Intenta primero con la sintaxis alternativa
    final response = await supabase
        .from('producto')
        .select('*, imagenes(*)')  // ← Cambio aquí: usa (*) en lugar de (url_img)
        .eq('id', idProducto)
        .single();

    print('Respuesta de Supabase:');
    print(response);
    
    if (response == null) {
      print('La respuesta es null');
      return null;
    }

    // Verificar si hay imágenes en la respuesta
    if (response['imagenes'] != null) {
      print('Se encontraron imágenes en la respuesta:');
      print(response['imagenes']);
      print('Tipo: ${response['imagenes'].runtimeType}');
    } else {
      print('No hay imágenes en la respuesta');
    }

    final producto = Producto.fromMap(response);
    
    
    return producto;
  } catch (e, stackTrace) {
    print('Error al obtener producto con imágenes: $e');
    print('Stack trace: $stackTrace');
    return null;
  }
}

// Si el método anterior no funciona, prueba este alternativo:
Future<Producto?> obtenerProductoConImagenesAlternativo(int idProducto) async {
  try {
    print('Consultando producto con ID: $idProducto');
    
    // Primero obtener el producto
    final productoResponse = await supabase
        .from('producto')
        .select()
        .eq('id', idProducto)
        .single();
    
    // Luego obtener las imágenes por separado
    final imagenesResponse = await supabase
        .from('imagenes')
        .select('url_img')
        .eq('id_producto', idProducto);
    
    
    // Combinar los datos manualmente
    productoResponse['imagenes'] = imagenesResponse;
    
    return Producto.fromMap(productoResponse);
  } catch (e, stackTrace) {
    print('Error en método alternativo: $e');
    print('Stack trace: $stackTrace');
    return null;
  }
}
  // Para obtener todos los productos con sus imágenes:
  Future<List<Producto>> obtenerTodosLosProductos() async {
    try {
      final response = await supabase
          .from('producto')
          .select('''
            *,
            imagenes (
              url_img
            )
          ''')
          .order('id');

      return (response as List)
          .map((item) => Producto.fromMap(item))
          .toList();
    } catch (e) {
      print('Error al obtener productos: $e');
      return [];
    }
  }

  // Agregar este método a tu clase Productocrudimpl

  /// Obtiene los productos agregados en los últimos 2 meses
  /// Ordena por fecha de creación descendente (más recientes primero)
  Future<List<Producto>> novedades() async {
    try {
      print('🆕 Buscando novedades (productos de los últimos 2 meses)...');
      
      // Calcular la fecha hace 2 meses
      final fechaLimite = DateTime.now().subtract(Duration(days: 60));
      final fechaLimiteStr = fechaLimite.toIso8601String();
      
      print('Fecha límite: $fechaLimiteStr');
      
      // Realizar la consulta filtrando por created_at
      final response = await supabase
          .from('producto')
          .select()
          .gte('created_at', fechaLimiteStr) // mayor o igual a la fecha límite
          .order('created_at', ascending: false); // más recientes primero
      
      // Verificar si la respuesta es nula o vacía
      if (response == null || response.isEmpty) {
        print('⚠️ No se encontraron novedades');
        return [];
      }

      // La respuesta ya es una lista
      final data = response as List;

      // Convertir cada elemento a Producto
      final List<Producto> productos = [];
      for (var item in data) {
        try {
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('❌ Error al convertir producto: $e');
          print('Tipo del item: ${item.runtimeType}');
          print('Datos del producto problemático: $item');
        }
      }

      print('✅ Se cargaron ${productos.length} novedades');
      return productos;

    } on PostgrestException catch (e) {
      print('❌ Error de Supabase: ${e.message}');
      print('Código: ${e.code}');
      print('Detalles: ${e.details}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error al leer novedades: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

/// Versión alternativa: obtiene las últimas N novedades sin filtro de fecha
/// Útil si quieres mostrar siempre los últimos productos agregados
  Future<List<Producto>> novedadesRecientes({int limite = 10}) async {
    try {
      print('Buscando las últimas $limite novedades...');
      
      // Realizar la consulta ordenando por created_at y limitando resultados
      final response = await supabase
          .from('producto')
          .select()
          .order('created_at', ascending: false) // más recientes primero
          .limit(limite); // limitar cantidad de resultados
      
      // Verificar si la respuesta es nula o vacía
      if (response == null || response.isEmpty) {
        print('⚠️ No se encontraron novedades');
        return [];
      }

      // La respuesta ya es una lista
      final data = response as List;

      // Convertir cada elemento a Producto
      final List<Producto> productos = [];
      for (var item in data) {
        try {
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('❌ Error al convertir producto: $e');
        }
      }

      print('✅ Se cargaron ${productos.length} novedades recientes');
      return productos;

    } on PostgrestException catch (e) {
      print('❌ Error de Supabase: ${e.message}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error al leer novedades recientes: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

 
  /// Obtiene todos los productos ordenados por recomendado (mayor a menor)
  Future<List<Producto>> productosRecomendados() async {
    try {
      print('Obteniendo productos ordenados por recomendación...');
      
      // Realizar la consulta ordenando por recomendado descendente
      final response = await supabase
          .from('producto')
          .select()
          .order('recomendado', ascending: false) // Mayor a menor (1 primero, luego 0)
          .order('created_at', ascending: false); // Desempate por fecha
      
      // Verificar si la respuesta es nula o vacía
      if (response == null || response.isEmpty) {
        print('No se encontraron productos');
        return [];
      }

      // La respuesta ya es una lista
      final data = response as List;

      // Convertir cada elemento a Producto
      final List<Producto> productos = [];
      for (var item in data) {
        try {
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('Error al convertir producto: $e');
          print('Tipo del item: ${item.runtimeType}');
          print('Datos del producto problemático: $item');
        }
      }

      print('Se cargaron ${productos.length} productos ordenados por recomendación');
      return productos;

    } on PostgrestException catch (e) {
      print('Error de Supabase: ${e.message}');
      print('Código: ${e.code}');
      print('Detalles: ${e.details}');
      return [];
    } catch (e, stackTrace) {
      print('Error al obtener productos recomendados: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Obtiene solo los productos marcados como recomendados (recomendado=1)
  /// Útil para mostrar una sección específica de "Productos Recomendados"
  Future<List<Producto>> soloRecomendados({int? limite}) async {
    try {
      print('Obteniendo solo productos recomendados...');
      
      // Construir la consulta
      var query = supabase
          .from('producto')
          .select()
          .eq('recomendado', 1) // Solo productos con recomendado=1
          .order('created_at', ascending: false); // Más recientes primero
      
      // Aplicar límite si se especificó
      if (limite != null) {
        query = query.limit(limite);
      }
      
      final response = await query;
      
      // Verificar si la respuesta es nula o vacía
      if (response == null || response.isEmpty) {
        print('No se encontraron productos recomendados');
        return [];
      }

      // La respuesta ya es una lista
      final data = response as List;

      // Convertir cada elemento a Producto
      final List<Producto> productos = [];
      for (var item in data) {
        try {
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('❌ Error al convertir producto: $e');
        }
      }

      print('Se encontraron ${productos.length} productos recomendados');
      return productos;

    } on PostgrestException catch (e) {
      print('❌ Error de Supabase: ${e.message}');
      print('Código: ${e.code}');
      print('Detalles: ${e.details}');
      return [];
    } catch (e, stackTrace) {
      print('Error al obtener solo recomendados: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Obtiene productos recomendados de una categoría específica
  Future<List<Producto>> recomendadosPorCategoria(String categoriaId, {int? limite}) async {
    try {
      print('Obteniendo recomendados de la categoría: $categoriaId');
      
      // Construir la consulta
      var query = supabase
          .from('producto')
          .select()
          .eq('id_categoria', categoriaId)
          .eq('recomendado', 1)
          .order('created_at', ascending: false);
      
      // Aplicar límite si se especificó
      if (limite != null) {
        query = query.limit(limite);
      }
      
      final response = await query;
      
      if (response == null || response.isEmpty) {
        print('No se encontraron productos recomendados para esta categoría');
        return [];
      }

      final data = response as List;

      final List<Producto> productos = [];
      for (var item in data) {
        try {
          final mapa = item as Map<String, dynamic>;
          productos.add(Producto.fromMap(mapa));
        } catch (e) {
          print('❌ Error al convertir producto: $e');
        }
      }

      print('Se encontraron ${productos.length} productos recomendados en la categoría');
      return productos;

    } on PostgrestException catch (e) {
      print('❌ Error de Supabase: ${e.message}');
      return [];
    } catch (e, stackTrace) {
      print('Error al obtener recomendados por categoría: $e');
      return [];
    }
  }

}