import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/src/model/usuario.dart';
import 'package:myapp/src/model/dao/usuariocrudimpl.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UsuarioCrud _usuarioCrud = UsuarioCrud();

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  // Sign up with email and password, and create record in usuario table
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nombre,
    required String usuario,
    required String telefono,
    required int fkCargo,
  }) async {
    try {
      // Configuramos la URL de redirección para la confirmación de email
      // En móvil usamos el esquema personalizado configurado en Supabase
      // En web, Supabase usa por defecto la URL del sitio configurada
      final String? redirectTo = kIsWeb 
          ? null 
          : 'io.supabase.flutter://login-callback/';

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectTo,
      );

      if (response.user != null) {
        final nuevoUsuario = Usuario(
          id: response.user!.id,
          nombre: nombre,
          usuario: usuario,
          telefono: telefono,
          fkCargo: fkCargo, 
        );
        
        await _usuarioCrud.crearUsuario(nuevoUsuario);
      }

      return response;
    } catch (e) {
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
