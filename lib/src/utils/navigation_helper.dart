import 'package:flutter/material.dart';
import 'package:myapp/src/routes/app_routes.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/model/categoria.dart';

/// Helper class para facilitar la navegación en toda la app
class NavigationHelper {
  /// Navegar a la página de inicio
  static void goToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  /// Navegar al detalle de un producto
  static void goToProductDetail(BuildContext context, Producto producto) {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: producto,
    );
  }

  /// Navegar a productos de una categoría
  static void goToCategoryProducts(BuildContext context, Categoria categoria) {
    Navigator.pushNamed(
      context,
      AppRoutes.categoryProducts,
      arguments: categoria,
    );
  }

  /// Navegar al carrito
  static void goToCart(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.cart);
  }

  /// Navegar a favoritos
  static void goToFavorites(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.favorites);
  }

  /// Navegar a búsqueda
  static void goToSearch(BuildContext context, {String? initialQuery}) {
    Navigator.pushNamed(
      context,
      AppRoutes.search,
      arguments: initialQuery,
    );
  }

  /// Navegar al perfil
  static void goToProfile(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  /// Navegar a configuración
  static void goToSettings(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.settings);
  }

  /// Volver atrás
  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Volver atrás con resultado
  static void goBackWithResult<T>(BuildContext context, T result) {
    Navigator.pop(context, result);
  }

  /// Reemplazar la ruta actual
  static void replaceTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navegar y limpiar todas las rutas anteriores
  static void goToAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Mostrar un diálogo de confirmación antes de navegar
  static Future<void> confirmAndNavigate(
    BuildContext context, {
    required String title,
    required String message,
    required String routeName,
    Object? arguments,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pushNamed(context, routeName, arguments: arguments);
    }
  }
}

/// Extension methods para hacer la navegación aún más sencilla
extension NavigationExtension on BuildContext {
  /// Navegar usando el contexto directamente
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(this, routeName, arguments: arguments);
  }

  /// Volver atrás
  void pop<T>([T? result]) {
    Navigator.pop(this, result);
  }

  /// Verificar si se puede volver atrás
  bool canPop() {
    return Navigator.canPop(this);
  }

  /// Ir al detalle del producto (atajo)
  void goToProduct(Producto producto) {
    NavigationHelper.goToProductDetail(this, producto);
  }

  /// Ir a la categoría (atajo)
  void goToCategory(Categoria categoria) {
    NavigationHelper.goToCategoryProducts(this, categoria);
  }
}