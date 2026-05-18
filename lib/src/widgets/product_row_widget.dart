// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductsRowWidget extends StatefulWidget {
  final Future<List<Producto>> Function() cargarProductos;
  final String titulo;
  final String? subtitulo;
  final bool mostrarFlechas; // Nuevo parámetro

  const ProductsRowWidget({
    Key? key,
    required this.cargarProductos,
    this.titulo = 'NUESTROS PRODUCTOS',
    this.subtitulo = 'Descubre nuestra colección de mobiliario de calidad',
    this.mostrarFlechas = true, // Por defecto mostrar flechas
  }) : super(key: key);

  @override
  _ProductsRowWidgetState createState() => _ProductsRowWidgetState();
}

class _ProductsRowWidgetState extends State<ProductsRowWidget> {
  late Future<List<Producto>> _productosFuture;
  final ScrollController _scrollController = ScrollController();
  bool _mostrarFlechaIzquierda = false;
  bool _mostrarFlechaDerecha = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();

    // Escuchar cambios en el scroll para mostrar/ocultar flechas
    _scrollController.addListener(_actualizarFlechas);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _cargarProductos() {
    _productosFuture = widget.cargarProductos();
  }

  void _actualizarFlechas() {
    setState(() {
      // Mostrar flecha izquierda si no está al inicio
      _mostrarFlechaIzquierda = _scrollController.offset > 0;

      // Mostrar flecha derecha si no está al final
      _mostrarFlechaDerecha =
          _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  void _scrollIzquierda() {
    _scrollController.animateTo(
      _scrollController.offset - 300,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollDerecha() {
    _scrollController.animateTo(
      _scrollController.offset + 300,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.titulo,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (widget.subtitulo != null) ...[
                  SizedBox(height: 8),
                  Text(
                    widget.subtitulo!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 24),

          // Row horizontal de productos con flechas
          SizedBox(
            height: _getCardHeight(context),
            child: FutureBuilder<List<Producto>>(
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
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
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

                return Stack(
                  children: [
                    // Lista de productos
                    ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 60),
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < productos.length - 1 ? 16 : 0,
                          ),
                          child: _buildProductCard(context, productos[index]),
                        );
                      },
                    ),

                    // Flecha izquierda (mismo estilo que CategoriesScrollWidget)
                    if (widget.mostrarFlechas && _mostrarFlechaIzquierda)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.chevron_left, size: 28),
                              onPressed: _scrollIzquierda,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                    // Flecha derecha (mismo estilo que CategoriesScrollWidget)
                    if (widget.mostrarFlechas && _mostrarFlechaDerecha)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.chevron_right, size: 28),
                              onPressed: _scrollDerecha,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _getCardHeight(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 420;
    if (width > 800) return 400;
    if (width > 600) return 380;
    return 360;
  }

  double _getCardWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 280;
    if (width > 800) return 260;
    if (width > 600) return 240;
    return 220;
  }

  Widget _buildProductCard(BuildContext context, Producto producto) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.getProductRoute(producto),
          arguments: producto,
        );
      },
      child: Container(
        width: _getCardWidth(context),
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
                    if (producto.esNuevo())
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'NUEVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gs. ${producto.precioFormateado}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
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
    final String url1 =
        'https://vgmuebleria.vercel.app/#/comprar//${_toSlug(producto.nombre)}';
    final String message =
        "${url1}\nHola te escribo desde la web, me interesa un mueble: ${producto.nombre}";
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
