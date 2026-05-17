import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget reutilizable para seleccionar imágenes desde galería o cámara
class ImagePickerWidget extends StatelessWidget {
  /// Callback que recibe los bytes de la imagen y el nombre del archivo
  final Function(Uint8List bytes, String fileName) onImageSelected;
  
  /// URL de imagen existente para mostrar como preview
  final String? currentImageUrl;
  
  /// Texto del botón
  final String label;

  const ImagePickerWidget({
    Key? key,
    required this.onImageSelected,
    this.currentImageUrl,
    this.label = 'Seleccionar imagen',
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        onImageSelected(bytes, pickedFile.name);
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        
        // Preview de la imagen actual
        if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
          Container(
            width: double.infinity,
            height: 150,
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                currentImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                ),
              ),
            ),
          ),
        
        // Botón de selección (solo Galería)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library, size: 18),
            label: const Text('Galería', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 88, 23, 23),
              side: const BorderSide(color: const Color.fromARGB(255, 88, 23, 23)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
