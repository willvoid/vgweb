import 'package:flutter/material.dart';
import 'package:myapp/src/pages/home_page.dart';
import 'package:myapp/src/pages/category_page.dart';
import 'package:myapp/src/pages/buscar_page.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/model/categoria.dart';
import '../pages/detail_page.dart';
import 'package:myapp/src/pages/login_page.dart';
import 'package:myapp/src/pages/register_page.dart';

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
      print('❌ Error: No se recibió un producto válido');
      return _errorRoute('Se requiere un producto válido');
    }

    // Manejar rutas de categoría con patrón /categoria/slug
    if (settings.name != null && settings.name!.startsWith('/categoria/')) {
      print('✅ Ruta de categoría detectada');
      if (settings.arguments is Categoria) {
        final categoria = settings.arguments as Categoria;
        print('✅ Navegando a categoría: ${categoria.nombre}');
        return _buildRoute(CategoryPage(categoria: categoria), settings);
      }
      print('❌ Error: No se recibió una categoría válida');
      return _errorRoute('Se requiere una categoría válida');
    }

    switch (settings.name) {
      // Página principal
      case AppRoutes.home:
        return _buildRoute(HomePage(), settings);

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
          return _buildRoute(
            BuscarPage(query: query, page: page),
            settings,
          );
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