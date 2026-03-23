import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageLocationWidget extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onLocationPressed;

  const ImageLocationWidget({
    Key? key,
    required this.imagePath,
    this.onLocationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagen que cubre el ancho de la pantalla
        Container(
          width: double.infinity,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Botón de ubicación flotante
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: onLocationPressed ?? () {
              // Acción por defecto si no se proporciona callback
              launch('https://maps.app.goo.gl/6Y4nuN3BWAagVrqYA');
            },
            backgroundColor: Colors.white,
            child: Icon(
              Icons.location_on,
              color: Colors.red,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}

// Ejemplo de uso completo
class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VG Muebles'),
        backgroundColor: Colors.brown[700],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ImageLocationWidget(
              imagePath: 'assets/images/tienda.jpg', // Cambia esto a tu ruta
              onLocationPressed: () {
                // Google Maps
                launch('https://maps.app.goo.gl/6Y4nuN3BWAagVrqYA');
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'VG Muebles y Electrodomésticos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}