import 'package:flutter/material.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/model/dao/productocrudimpl.dart';
import 'package:myapp/src/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ProductoAleatorioPopup extends StatefulWidget {
  const ProductoAleatorioPopup({Key? key}) : super(key: key);

  @override
  State<ProductoAleatorioPopup> createState() => _ProductoAleatorioPopupState();
}

class _ProductoAleatorioPopupState extends State<ProductoAleatorioPopup> {
  Producto? productoAleatorio;
  bool mostrarPopup = false;
  bool isLoading = true;
  final Productocrudimpl _productoCrud = Productocrudimpl();

  @override
  void initState() {
    super.initState();
    print('🎯 ProductoAleatorioPopup: initState');
    _verificarYMostrarPopup();
  }

  Future<void> _verificarYMostrarPopup() async {
    try {
      print('🔍 Verificando si debe mostrar popup...');
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener el timestamp de la última vez que se mostró
      final ultimaVezMostrado = prefs.getInt('popup_ultimo_timestamp') ?? 0;
      final ahora = DateTime.now().millisecondsSinceEpoch;
      
      // Si han pasado más de 5 segundos desde que se abrió la app, mostrar el popup
      // (esto significa que es una nueva sesión/recarga)
      final yaVioPopupEnEstaSesion = (ahora - ultimaVezMostrado) < 5000; // 5 segundos
      
      print('📊 Última vez mostrado: ${DateTime.fromMillisecondsSinceEpoch(ultimaVezMostrado)}');
      print('📊 Ya vio popup en esta sesión: $yaVioPopupEnEstaSesion');

      if (!yaVioPopupEnEstaSesion) {
        await _cargarProductoAleatorio();
        if (productoAleatorio != null) {
          // Guardar el timestamp actual
          await prefs.setInt('popup_ultimo_timestamp', ahora);
          
          setState(() {
            mostrarPopup = true;
          });
          print('✅ Popup configurado para mostrarse (nueva sesión)');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print('⏭️ Usuario ya vio el popup en esta sesión');
      }
    } catch (e) {
      print('❌ Error al verificar popup: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cargarProductoAleatorio() async {
    try {
      print('📦 Cargando productos...');
      // Obtener todos los productos
      final productos = await _productoCrud.leerProductos();
      
      print('📊 Total productos: ${productos.length}');
      
      if (productos.isNotEmpty) {
        // Seleccionar uno aleatorio
        final random = Random();
        final productoSeleccionado = productos[random.nextInt(productos.length)];
        
        print('🎲 Producto aleatorio seleccionado: ${productoSeleccionado.nombre}');
        print('🖼️ Imagen: ${productoSeleccionado.img}');
        
        setState(() {
          productoAleatorio = productoSeleccionado;
          isLoading = false;
        });
      } else {
        print('⚠️ No hay productos disponibles');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar producto aleatorio: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cerrarPopup() async {
    print('❌ Cerrando popup...');
    // Ya no necesitamos guardar nada al cerrar, 
    // el timestamp ya se guardó cuando se mostró
    setState(() {
      mostrarPopup = false;
    });
  }

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Build popup - mostrarPopup: $mostrarPopup, producto: ${productoAleatorio?.nombre}');
    
    if (!mostrarPopup || productoAleatorio == null) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMobile = size.height < 700;
    final cardWidth = isSmallScreen ? size.width * 0.9 : 600.0;
    final imageHeight = isMobile ? 250.0 : (isSmallScreen ? 300.0 : 400.0);

    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // Fondo oscuro que cierra el popup al tocar
          GestureDetector(
            onTap: _cerrarPopup,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Contenido del popup - Centrado y con scroll
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: cardWidth,
                margin: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isSmallScreen ? 20 : 40,
                ),
                child: Stack(
                  children: [
                    // Card principal
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Imagen del producto
                            Stack(
                              children: [
                                // Imagen principal
                                Container(
                                  height: imageHeight,
                                  width: double.infinity,
                                  color: Colors.white,
                                  child: productoAleatorio!.img != null && productoAleatorio!.img!.isNotEmpty
                                      ? Image.network(
                                          productoAleatorio!.img!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('❌ Error al cargar imagen: $error');
                                            return Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 80,
                                                color: Colors.grey.withOpacity(0.3),
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF8B1538),
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.chair,
                                            size: 100,
                                            color: Colors.grey.withOpacity(0.3),
                                          ),
                                        ),
                                ),
                                
                                // Badge de producto destacado (más pequeño)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.yellow[300]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.yellow[300],
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'DESTACADO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Gradiente sutil en la parte inferior
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Color(0xFF8B1538).withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Información del producto (sección más pequeña)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF8B1538),
                                    Color(0xFFB31D47),
                                  ],
                                ),
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                              child: Column(
                                children: [
                                  // Nombre del producto
                                  Text(
                                    productoAleatorio!.nombre.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 16 : 18),
                                  
                                  // Botón Ver Producto
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _cerrarPopup();
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.getProductRoute(productoAleatorio!),
                                          arguments: productoAleatorio,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Color(0xFF8B1538),
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 14 : 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 8,
                                        shadowColor: Colors.black.withOpacity(0.4),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'VER PRODUCTO',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_rounded, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Botón cerrar (X)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _cerrarPopup,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para envolver tu MaterialApp y mostrar el popup
class AppConPopupInicial extends StatelessWidget {
  final Widget child;

  const AppConPopupInicial({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const ProductoAleatorioPopup(),
      ],
    );
  }
}