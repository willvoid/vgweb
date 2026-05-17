import 'package:flutter/material.dart';
import 'package:myapp/src/model/dao/productocrudimpl.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/widgets/footer_widget.dart';
import 'package:myapp/src/widgets/base_page_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatefulWidget {
  final Producto producto;

  const ProductDetailPage({
    Key? key,
    required this.producto,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _cantidad = 1;
  bool _isFavorite = false;
  late String _imagenActual;
  late List<String> _imagenesProducto;
  bool _isLoadingImages = true;
  final Productocrudimpl _productoCrud = Productocrudimpl();

  @override
  void initState() {
    super.initState();
    // Inicializar con la imagen principal
    _imagenActual = widget.producto.img;
    _imagenesProducto = [widget.producto.img];
    
    // Cargar las imágenes adicionales desde la base de datos
    _cargarImagenesAdicionales();
  }

  Future<void> _cargarImagenesAdicionales() async {
    if (widget.producto.id == null) {
      setState(() => _isLoadingImages = false);
      return;
    }

    try {
      final productoConImagenes = await _productoCrud.obtenerProductoConImagenesAlternativo(widget.producto.id!);
      
      if (productoConImagenes != null) {
        setState(() {
          _imagenesProducto = productoConImagenes.obtenerTodasLasImagenes();
          _isLoadingImages = false;
        });
        print('✅ Se cargaron ${_imagenesProducto.length} imágenes para el producto');
      } else {
        setState(() => _isLoadingImages = false);
        print('⚠️ No se encontraron imágenes adicionales');
      }
    } catch (e) {
      print('❌ Error al cargar imágenes: $e');
      setState(() => _isLoadingImages = false);
    }
  }

  void _cambiarImagen(String nuevaImagen) {
    setState(() {
      _imagenActual = nuevaImagen;
    });
  }

  void _incrementarCantidad() {
    if (widget.producto.stock == null || _cantidad < widget.producto.stock!) {
      setState(() {
        _cantidad++;
      });
    }
  }

  void _decrementarCantidad() {
    if (_cantidad > 1) {
      setState(() {
        _cantidad--;
      });
    }
  }

  Future<void> _openWhatsApp(Producto producto) async {
    final String phoneNumber = "595985255566";
    final String url1 = 'https://vgmuebleria.com.py/comprar/${_toSlug(producto.nombre)}';
    final String message = "${url1}\nHola te escribo desde la web, me interesa un mueble: ${producto.nombre}";
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$message");
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo abrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al abrir WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al contactar por WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _toggleFavorito() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite 
            ? 'Agregado a favoritos' 
            : 'Eliminado de favoritos'
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePageWidget(
      showCategoryNavigation: false, // No mostrar navegación de categorías en detalle de producto
      children: [
        _buildProductContent(),
        FooterWidget(),
      ],
    );
  }

  Widget _buildProductContent() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 800;
          
          if (isWideScreen) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Galería de imágenes + Imagen principal
                Expanded(
                  flex: 1,
                  child: _buildImageGallerySection(),
                ),
                SizedBox(width: 32),
                // Información del producto
                Expanded(
                  flex: 1,
                  child: _buildProductInfo(),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildImageGallerySection(),
                SizedBox(height: 24),
                _buildProductInfo(),
              ],
            );
          }
        },
      ),
    );
  }

  // Nueva sección que combina galería + imagen principal
  Widget _buildImageGallerySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 400;
        
        if (isWideScreen) {
          // Layout desktop: galería a la izquierda, imagen principal a la derecha
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Galería de miniaturas (vertical)
              _buildVerticalThumbnailGallery(),
              SizedBox(width: 16),
              // Imagen principal
              Expanded(
                child: _buildProductImage(),
              ),
            ],
          );
        } else {
          // Layout móvil: imagen principal arriba, galería abajo
          return Column(
            children: [
              _buildProductImage(),
              SizedBox(height: 16),
              _buildHorizontalThumbnailGallery(),
            ],
          );
        }
      },
    );
  }

  // Galería vertical (para desktop)
  Widget _buildVerticalThumbnailGallery() {
    return Container(
      width: 80,
      child: Column(
        children: _imagenesProducto.map((imagen) {
          bool isSelected = imagen == _imagenActual;
          return GestureDetector(
            onTap: () => _cambiarImagen(imagen),
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color.fromARGB(255, 88, 23, 23) : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color.fromARGB(255, 88, 23, 23).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  imagen,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Galería horizontal (para móvil)
  Widget _buildHorizontalThumbnailGallery() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _imagenesProducto.map((imagen) {
          bool isSelected = imagen == _imagenActual;
          return GestureDetector(
            onTap: () => _cambiarImagen(imagen),
            child: Container(
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color.fromARGB(255, 88, 23, 23) : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color.fromARGB(255, 88, 23, 23).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  imagen,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductImage() {
    return Hero(
      tag: 'producto_${widget.producto.id}',
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 500,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _imagenActual,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 400,
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey[500],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Imagen no disponible',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 768;
        
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.producto.nombre,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 12),
              
              Text(
                '${widget.producto.precioFormateado} Gs',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 12),
              
              if (widget.producto.stock != null)
                _buildStockBadge(),
              SizedBox(height: 24),
              
              if (widget.producto.descripcion != null &&
                  widget.producto.descripcion!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.producto.descripcion!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              
              Text(
                'Características',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              _buildCaracteristica(
                Icons.inventory_2,
                'Código',
                widget.producto.id.toString(),
              ),
              SizedBox(height: 24),
              
              _buildQuantitySelector(),
              SizedBox(height: 16),
              
              Text(
                'Total: ${Producto.formatearPrecio(widget.producto.precio * _cantidad)} Gs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              
              _buildAddToCartButton(52),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.producto.nombre,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '${widget.producto.precioFormateado} Gs',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    if (widget.producto.stock != null) _buildStockBadge(),
                    SizedBox(height: 32),
                    Text(
                      'Características',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildCaracteristica(
                      Icons.inventory_2,
                      'Código',
                      widget.producto.id.toString(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 40),
              
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.producto.descripcion != null &&
                        widget.producto.descripcion!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            widget.producto.descripcion!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
                    
                    _buildQuantitySelector(),
                    SizedBox(height: 24),
                    
                    _buildAddToCartButton(56),
                    SizedBox(height: 12),
                    
                    Text(
                      'Total: ${Producto.formatearPrecio(widget.producto.precio * _cantidad)} Gs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStockBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.producto.stock! > 10
            ? Colors.green[50]
            : widget.producto.stock! > 0
                ? Colors.orange[50]
                : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.producto.stock! > 0 ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: widget.producto.stock! > 10
                ? Colors.green[700]
                : widget.producto.stock! > 0
                    ? Colors.orange[700]
                    : Colors.red[700],
          ),
          SizedBox(width: 6),
          Text(
            widget.producto.stock! > 10
                ? 'En stock (${widget.producto.stock})'
                : widget.producto.stock! > 0
                    ? 'Últimas ${widget.producto.stock} unidades'
                    : 'Sin stock',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.producto.stock! > 10
                  ? Colors.green[700]
                  : widget.producto.stock! > 0
                      ? Colors.orange[700]
                      : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text(
          'Cantidad:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: _decrementarCantidad,
                color: _cantidad > 1 ? Colors.black : Colors.grey,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _cantidad.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _incrementarCantidad,
                color: (widget.producto.stock == null ||
                        _cantidad < widget.producto.stock!)
                    ? Colors.black
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(double height) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton.icon(
        onPressed: () {
          _openWhatsApp(widget.producto);
        },
        icon: Image.asset("assets/icons/whatsapp.png", width: 26, height: 26),
        label: Text(
          (widget.producto.stock == null || widget.producto.stock! > 0)
              ? 'HACER PEDIDO'
              : 'SIN STOCK',
          style: TextStyle(
            fontSize: height * 0.3,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildCaracteristica(IconData icon, String titulo, String valor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue[700]),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}