import 'package:flutter/material.dart';
import 'package:myapp/src/model/dao/productocrudimpl.dart';
import 'package:myapp/src/widgets/footer_widget.dart';
import 'package:myapp/src/widgets/base_page_widget.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:url_launcher/url_launcher.dart';

class BuscarPage extends StatefulWidget {
  final String query;
  final int page;

  const BuscarPage({Key? key, required this.query, this.page = 1})
      : super(key: key);

  @override
  _BuscarPageState createState() => _BuscarPageState();
}

class _BuscarPageState extends State<BuscarPage> {
  final Productocrudimpl _productoCrud = Productocrudimpl();
  List<Producto> _productos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _buscarProductos();
  }

  Future<void> _buscarProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final productos = await _productoCrud.buscarProductos(widget.query);
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar productos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageWidget(
      showCategoryNavigation: false, // No mostrar navegación de categorías en búsqueda
      onCategoryTap: (category) {
        // Navegar a la categoría si se desea
        print('Categoría seleccionada: $category');
      },
      children: [
        // Banner de búsqueda
        _buildSearchBanner(),

        // Resultados de búsqueda
        _buildSearchResults(),

        // Footer
        FooterWidget(),
      ],
    );
  }

  Widget _buildSearchBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 88, 23, 23),
            Color.fromARGB(255, 120, 40, 40),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESULTADOS DE BÚSQUEDA',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Búsqueda: "${widget.query}"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (!_isLoading)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '${_productos.length} producto(s) encontrado(s)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(64),
        child: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 88, 23, 23),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        padding: EdgeInsets.all(64),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_productos.isEmpty) {
      return Container(
        padding: EdgeInsets.all(64),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No se encontraron productos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Intenta con otros términos de búsqueda',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SearchResultsGrid(productos: _productos);
  }
}

// Widget reutilizable para mostrar el grid de resultados
class SearchResultsGrid extends StatelessWidget {
  final List<Producto> productos;

  const SearchResultsGrid({Key? key, required this.productos})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: GridView.builder(
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
          return ProductCard(producto: productos[index]);
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }
}

// Widget reutilizable para la tarjeta de producto
class ProductCard extends StatelessWidget {
  final Producto producto;

  const ProductCard({Key? key, required this.producto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/comprar/${producto.nombre.toLowerCase().replaceAll(' ', '-')}',
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

                    // Badge de stock bajo
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
                            producto.descripcion!,
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
                        if (producto.precio != null)
                          Text(
                            'Gs. ${producto.precioFormateado}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 88, 23, 23),
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
                              _openWhatsApp2(producto);
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

  Future<void> _openWhatsApp2(Producto producto) async {
    final String phoneNumber = "595985255566";
    final String url1 =
        'https://vgmuebleria.com.py/comprar/${_toSlug(producto.nombre)}';
    final String message2 =
        "${url1}\nHola te escribo desde la web, me interesa un mueble: ${producto.nombre}";
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$message2");
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