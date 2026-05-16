import 'package:myapp/src/model/cargo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CargoCrud {
  Future<List<Cargo>> leerCargos() async {
    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('cargo')
          .select()
          .order('cargo', ascending: true);
          
      if (data.isEmpty) {
        return [];
      }

      return data.map((mapa) => Cargo.fromMap(mapa)).toList();

    } catch (e) {
      print('Error al leer los cargos: $e');
      return [];
    }
  }
}
