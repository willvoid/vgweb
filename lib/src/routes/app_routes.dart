import 'package:flutter/material.dart';
import 'package:myapp/src/pages/home_page.dart';
import 'package:myapp/src/pages/category_page.dart';
import 'package:myapp/src/pages/buscar_page.dart';
import 'package:myapp/src/pages/admin/admin_page.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/model/categoria.dart';
import '../pages/detail_page.dart';
import 'package:myapp/src/pages/login_page.dart';
import 'package:myapp/src/pages/register_page.dart';
import 'package:myapp/src/model/dao/productocrudimpl.dart';
import 'package:myapp/src/model/dao/categoriacrudimpl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Clase que maneja todas las rutas de la aplicación
class AppRoutes {
  // Nombres de rutas como constantes
  static const String home = '/';
  static const String productDetail = '/product_detail';
  static const String categoryProducts = '/category_products';
  static const String cart = '/cart';
  static const String favorites = '/favorites';
  static const String search = '/buscador';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String register = '/register';
  static const String admin = '/admin';

  /// Convierte texto a un slug URL-friendly
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

  /// Genera la ruta completa para una categoría
  static String getCategoryRoute(Categoria categoria) {
    return '/categoria/${_toSlug(categoria.nombre)}';
  }

  /// Genera la ruta completa para un producto
  static String getProductRoute(Producto producto) {
    return '/comprar/${_toSlug(producto.nombre)}';
  }

  /// Genera las rutas dinámicamente según el nombre y argumentos
  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('🚀 Navegando a: ${settings.name}');
    print('🚀 Argumentos: ${settings.arguments.runtimeType}');

    // Manejar rutas de producto con patrón /comprar/slug
    if (settings.name != null && settings.name!.startsWith('/comprar/')) {
      print('✅ Ruta de producto detectada');
      if (settings.arguments is Producto) {
        final producto = settings.arguments as Producto;
        print('✅ Navegando a producto: ${producto.nombre}');
        return _buildRoute(ProductDetailPage(producto: producto), settings);
      }
      // Acceso directo por URL (sin argumentos)
      final slug = settings.name!.replaceFirst('/comprar/', '');
      print('ℹ️ Cargando producto por slug: $slug');
      return _buildRoute(ProductLoaderPage(slug: slug), settings);
    }

    // Manejar rutas de categoría con patrón /categoria/slug
    if (settings.name != null && settings.name!.startsWith('/categoria/')) {
      print('✅ Ruta de categoría detectada');
      if (settings.arguments is Categoria) {
        final categoria = settings.arguments as Categoria;
        print('✅ Navegando a categoría: ${categoria.nombre}');
        return _buildRoute(CategoryPage(categoria: categoria), settings);
      }
      // Acceso directo por URL (sin argumentos)
      final slug = settings.name!.replaceFirst('/categoria/', '');
      print('ℹ️ Cargando categoría por slug: $slug');
      return _buildRoute(CategoryLoaderPage(slug: slug), settings);
    }

    switch (settings.name) {
      // Página principal
      case AppRoutes.home:
        final session = Supabase.instance.client.auth.currentSession;
        return _buildRoute(session == null ? LoginPage() : HomePage(), settings);

      // Detalle de producto (ruta antigua, mantener por compatibilidad)
      case AppRoutes.productDetail:
        if (settings.arguments is Producto) {
          final producto = settings.arguments as Producto;
          return _buildRoute(ProductDetailPage(producto: producto), settings);
        }
        return _errorRoute('Se requiere un producto válido');

      // Productos por categoría (ruta antigua, mantener por compatibilidad)
      case AppRoutes.categoryProducts:
        if (settings.arguments is Categoria) {
          final categoria = settings.arguments as Categoria;
          return _buildRoute(CategoryPage(categoria: categoria), settings);
        }
        return _errorRoute('Se requiere una categoría válida');

      // Búsqueda
      case AppRoutes.search:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final query = args['q'] as String? ?? '';
          final page = args['page'] as int? ?? 1;
          return _buildRoute(BuscarPage(query: query, page: page), settings);
        }
        return _errorRoute('Se requieren parámetros de búsqueda válidos');

      // Carrito de compras
      case AppRoutes.cart:
        return _buildRoute(CartPage(), settings);

      // Favoritos
      case AppRoutes.favorites:
        return _buildRoute(FavoritesPage(), settings);

      // Perfil
      case AppRoutes.profile:
        return _buildRoute(ProfilePage(), settings);

      // Configuración
      case AppRoutes.settings:
        return _buildRoute(SettingsPage(), settings);

      // Login y Registro
      case AppRoutes.login:
        return _buildRoute(LoginPage(), settings);

      case AppRoutes.register:
        return _buildRoute(RegisterPage(), settings);

      case AppRoutes.admin:
        return _buildRoute(const AdminPage(), settings);

      // Ruta por defecto (error)
      default:
        return _errorRoute('Ruta no encontrada: ${settings.name}');
    }
  }

  /// Construye una ruta con transición personalizada
  static Route<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  /// Construye una ruta con animación personalizada (fade)
  static Route<dynamic> _buildFadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Construye una ruta con animación de slide desde abajo
  static Route<dynamic> _buildSlideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Página de error cuando la ruta no existe o los argumentos son inválidos
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Error'), backgroundColor: Colors.red),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'Oops!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(home, (route) => false);
                  },
                  icon: Icon(Icons.home),
                  label: Text('Volver al inicio'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Páginas placeholder
class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Carrito')),
      body: Center(child: Text('Carrito de Compras')),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favoritos')),
      body: Center(child: Text('Productos Favoritos')),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Perfil')),
      body: Center(child: Text('Mi Perfil')),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configuración')),
      body: Center(child: Text('Configuración')),
    );
  }
}

// ---------------------------------------------------------
// Loaders para enlaces directos (Deep Linking)
// ---------------------------------------------------------

class ProductLoaderPage extends StatefulWidget {
  final String slug;

  const ProductLoaderPage({Key? key, required this.slug}) : super(key: key);

  @override
  _ProductLoaderPageState createState() => _ProductLoaderPageState();
}

class _ProductLoaderPageState extends State<ProductLoaderPage> {
  bool _isLoading = true;
  Producto? _producto;
  final Productocrudimpl _productoCrud = Productocrudimpl();

  @override
  void initState() {
    super.initState();
    _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    try {
      final productos = await _productoCrud.leerProductos();
      final productoEncontrado = productos.cast<Producto?>().firstWhere(
        (p) => p != null && AppRoutes._toSlug(p.nombre) == widget.slug,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _producto = productoEncontrado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_producto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.red),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Oops!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Producto no encontrado',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false),
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ProductDetailPage(producto: _producto!);
  }
}

class CategoryLoaderPage extends StatefulWidget {
  final String slug;

  const CategoryLoaderPage({Key? key, required this.slug}) : super(key: key);

  @override
  _CategoryLoaderPageState createState() => _CategoryLoaderPageState();
}

class _CategoryLoaderPageState extends State<CategoryLoaderPage> {
  bool _isLoading = true;
  Categoria? _categoria;
  final CategoriaCrud _categoriaCrud = CategoriaCrud();

  @override
  void initState() {
    super.initState();
    _cargarCategoria();
  }

  Future<void> _cargarCategoria() async {
    try {
      final categorias = await _categoriaCrud.leerCategorias();
      final categoriaEncontrada = categorias.cast<Categoria?>().firstWhere(
        (c) => c != null && AppRoutes._toSlug(c.nombre) == widget.slug,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _categoria = categoriaEncontrada;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_categoria == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.red),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Oops!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Categoría no encontrada',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false),
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CategoryPage(categoria: _categoria!);
  }
}
