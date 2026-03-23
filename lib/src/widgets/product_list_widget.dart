// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/model/dao/productocrudimpl.dart';
import 'package:myapp/src/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductsListWidget extends StatefulWidget {
  final String? categoriaId; // Opcional: para filtrar por categoría
  final String titulo;

  const ProductsListWidget({
    Key? key,
    this.categoriaId,
    this.titulo = 'NUESTROS PRODUCTOS',
  }) : super(key: key);

  @override
  _ProductsListWidgetState createState() => _ProductsListWidgetState();
}

class _ProductsListWidgetState extends State<ProductsListWidget> {
  Productocrudimpl crud = Productocrudimpl();
  late Future<List<Producto>> _productosFuture;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  void _cargarProductos() {
    if (widget.categoriaId != null) {
      // Si hay categoría, filtrar por ella
      _productosFuture = crud.leerProductosPorCategoria(widget.categoriaId!);
    } else {
      // Si no, cargar todos
      _productosFuture = crud.leerProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Text(
            widget.titulo,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Descubre nuestra colección de mobiliario de calidad',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Grid de productos
          FutureBuilder<List<Producto>>(
            future: _productosFuture,
            builder: (context, snapshot) {
              // Mientras carga
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Si hay error
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar productos',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Si no hay datos o está vacío
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay productos disponibles',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Datos cargados exitosamente
              final productos = snapshot.data!;

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getCrossAxisCount(context),
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(context, productos[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Determina cuántas columnas según el ancho de pantalla
  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildProductCard(BuildContext context, Producto producto) {
    return GestureDetector(
      onTap: () {
        // Navegar al detalle del producto usando rutas con slug
        Navigator.pushNamed(
          context,
          AppRoutes.getProductRoute(
            producto,
          ), // Genera: /comprar/nombre-del-producto
          arguments: producto,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      producto.img,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Sin imagen',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),

                    // Badge de stock bajo (opcional)
                    if (producto.stock != null && producto.stock! < 5)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Últimas unidades',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Información del producto
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del producto
                        Text(
                          producto.nombre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),

                        // Descripción corta
                        if (producto.descripcion != null)
                          Text(
                            producto.descripcion,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),

                    // Precio y botón
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Precio
                        Text(
                          '\$${producto.precio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),

                        // Botón de acción
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Image.asset(
                              "assets/icons/whatsapp.png",
                              width: 26,
                              height: 26,
                            ),
                            color: Colors.white,
                            onPressed: () {
                              _openWhatsApp(producto);
                            },
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(Producto producto) async {
    final String phoneNumber = "595985255566";
    final String url1 = 'https://vgmuebleria.com.py/comprar/${_toSlug(producto.nombre)}';
    final String message = "${url1}\nHola te escribo desde la web, me interesa un mueble: ${producto.nombre}";
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$message");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw "No se pudo abrir WhatsApp";
    }
  }

  static String _toSlug(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
  }
}
