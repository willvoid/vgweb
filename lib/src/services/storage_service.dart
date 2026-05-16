import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sube una imagen al bucket especificado y retorna la URL pública
  /// [bucketName] - nombre del bucket ('imagenes' o 'categoria')
  /// [bytes] - datos binarios del archivo
  /// [fileName] - nombre del archivo (sin ruta)
  Future<String?> subirImagen({
    required String bucketName,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      // Generar un nombre único para evitar colisiones
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last;
      final uniqueName = '${timestamp}_$fileName';

      // Subir al bucket
      await _supabase.storage.from(bucketName).uploadBinary(
            uniqueName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: true,
            ),
          );

      // Obtener la URL pública
      final url = _supabase.storage.from(bucketName).getPublicUrl(uniqueName);

      print('✅ Imagen subida exitosamente: $url');
      return url;
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      return null;
    }
  }

  /// Elimina una imagen del bucket por su URL
  Future<bool> eliminarImagen({
    required String bucketName,
    required String imageUrl,
  }) async {
    try {
      // Extraer el path del archivo desde la URL
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      // El path dentro del bucket es lo que viene después de /object/public/bucketName/
      final bucketIndex = segments.indexOf(bucketName);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
        print('❌ No se pudo extraer el path del archivo');
        return false;
      }
      final filePath = segments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage.from(bucketName).remove([filePath]);
      print('✅ Imagen eliminada del storage: $filePath');
      return true;
    } catch (e) {
      print('❌ Error al eliminar imagen del storage: $e');
      return false;
    }
  }
}
