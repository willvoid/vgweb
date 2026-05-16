import 'package:myapp/src/model/usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class UsuarioCrud {
  Future<Usuario?> obtenerUsuario(String id) async {
    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('usuario')
          .select()
          .eq('id', id);

      if (data.isEmpty) {
        return null;
      }

      return Usuario.fromMap(data.first);
    } catch (e) {
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  Future<bool> crearUsuario(Usuario usuario) async {
    try {
      await supabase.from('usuario').insert(usuario.toMap());
      return true;
    } catch (e) {
      print('Error al crear usuario: $e');
      return false;
    }
  }
}
