import 'package:flutter/material.dart';
import 'package:myapp/src/model/categoria.dart';
import 'package:myapp/src/model/dao/categoriacrudimpl.dart';
import 'package:myapp/src/routes/app_routes.dart';
import 'package:myapp/src/widgets/side_bar_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget base reutilizable con header fijo y navegación de categorías
/// Puede usarse en HomePage, CategoryPage, ProductPage, etc.
class BasePageWidget extends StatefulWidget {
  /// Contenido principal de la página (se mostrará debajo del header)
  final List<Widget> children;
  
  /// Categoría actualmente seleccionada (opcional)
  final String? selectedCategory;
  
  /// Mostrar o no la barra de navegación de categorías
  final bool showCategoryNavigation;
  
  /// Widget personalizado para el FloatingActionButton (opcional)
  final Widget? floatingActionButton;
  
  /// Callback cuando se presiona una categoría
  final Function(String)? onCategoryTap;

  const BasePageWidget({
    Key? key,
    required this.children,
    this.selectedCategory,
    this.showCategoryNavigation = true,
    this.floatingActionButton,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  State<BasePageWidget> createState() => _BasePageWidgetState();
}

class _BasePageWidgetState extends State<BasePageWidget> {
  final String phoneNumber = "595985255566";
  final String message = "Hola, me interesa un producto";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  final CategoriaCrud _categoriaCrud = CategoriaCrud();
  
  late Future<List<Categoria>> _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = _categoriaCrud.leerCategorias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _realizarBusqueda() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/buscador',
        arguments: {'q': query, 'page': 1},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SideBarWidget(),
      floatingActionButton: widget.floatingActionButton ??
          FloatingActionButton(
            onPressed: _openWhatsApp,
            backgroundColor: Colors.green,
            tooltip: 'Contactar por WhatsApp',
            child: Image.asset(
              "assets/icons/whatsapp.png",
              width: 26,
              height: 26,
            ),
          ),
      body: CustomScrollView(
        slivers: [
          // Header fijo (sin categorías)
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              child: _buildFixedHeader(context),
            ),
          ),

          // Navegación de categorías (desaparece al hacer scroll) - opcional
          if (widget.showCategoryNavigation)
            SliverPersistentHeader(
              floating: true,
              delegate: _CategoryDelegate(
                child: _buildCategoryNavigation(),
              ),
            ),

          // Contenido que hace scroll
          SliverList(
            delegate: SliverChildListDelegate(widget.children),
          ),
        ],
      ),
    );
  }

  // Header fijo (logo, búsqueda)
  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 23, 23),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row con menú hamburguesa y logo
          Row(
            children: [
              // Menú hamburguesa
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),

              // Logo centrado
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navegar al home si no estamos ya ahí
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  child: Center(
                    child: Text(
                      'VG MUEBLERIA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Espacio para mantener el logo centrado
              SizedBox(width: 48),
            ],
          ),

          SizedBox(height: 12),

          // Campo de búsqueda
          Center(
            child: Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => _realizarBusqueda(),
                decoration: InputDecoration(
                  hintText: 'Buscar muebles...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    onPressed: _realizarBusqueda,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navegación de categorías sin flechas
  Widget _buildCategoryNavigation() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 23, 23),
      ),
      child: FutureBuilder<List<Categoria>>(
        future: _categoriasFuture,
        builder: (context, snapshot) {
          // Mientras carga, mostrar un indicador
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }

          // Si hay error, mostrar categorías por defecto
          if (snapshot.hasError) {
            print('Error al cargar categorías: ${snapshot.error}');
          }

          // Obtener las categorías de la BD o usar lista vacía
          final categoriasDB = snapshot.data ?? [];

          return ListView(
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              // Primero "NOVEDADES"
              _buildCategoryItemText(
                'NOVEDADES',
                isSelected: widget.selectedCategory?.toUpperCase() == 'NOVEDADES',
                onTap: () {
                  // Navegar a novedades
                  Navigator.pushNamed(context, AppRoutes.home);
                  if (widget.onCategoryTap != null) {
                    widget.onCategoryTap!('NOVEDADES');
                  }
                },
              ),
              
              // Luego las categorías de la BD
              ...categoriasDB.map((categoria) => _buildCategoryItemFromDB(
                categoria,
                isSelected: widget.selectedCategory?.toUpperCase() == 
                            categoria.nombre.toUpperCase(),
              )),
            ],
          );
        },
      ),
    );
  }

  // Item de categoría de texto simple (para NOVEDADES)
  Widget _buildCategoryItemText(String title, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 24),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 2,
              width: title.length * 8.0,
              color: isSelected ? Colors.white : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  // Item de categoría desde la BD
  Widget _buildCategoryItemFromDB(Categoria categoria, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        // Navegar a la página de categoría
        Navigator.pushNamed(
          context,
          AppRoutes.getCategoryRoute(categoria),
          arguments: categoria,
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 24),
        child: Column(
          children: [
            Text(
              categoria.nombre.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 2,
              width: categoria.nombre.length * 8.0,
              color: isSelected ? Colors.white : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
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
}

// Delegate para el header fijo
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _HeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 120.0;

  @override
  double get minExtent => 120.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

// Delegate para las categorías (desaparecen)
class _CategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 52.0;

  @override
  double get minExtent => 52.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}