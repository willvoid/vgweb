import 'package:flutter/material.dart';
import 'package:myapp/src/model/categoria.dart';
import 'package:myapp/src/widgets/footer_widget.dart';
import 'package:myapp/src/widgets/product_list_widget.dart';
import 'package:myapp/src/widgets/base_page_widget.dart';

class CategoryPage extends StatelessWidget {
  final Categoria categoria;

  const CategoryPage({Key? key, required this.categoria}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageWidget(
      selectedCategory: categoria.nombre,
      showCategoryNavigation: true,
      onCategoryTap: (category) {
        // TODO: Navegar a la página de otra categoría si es necesario
        print('Cambiar a categoría: $category');
      },
      children: [
        // Banner de categoría (opcional - descomenta si lo necesitas)
        // _buildCategoryBanner(),

        // Lista de productos filtrados por categoría
        ProductsListWidget(
          categoriaId: categoria.id.toString(),
          titulo: categoria.nombre.toUpperCase(),
        ),

        FooterWidget(),
      ],
    );
  }

  // Banner de categoría (opcional)
  Widget _buildCategoryBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Icono de categoría
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              _getCategoryIcon(),
              size: 48,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),

          // Nombre de categoría
          Text(
            categoria.nombre,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),

          // Descripción de categoría (si existe)
          if (categoria.descripcion != null &&
              categoria.descripcion!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                categoria.descripcion!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // Obtener icono según el nombre de la categoría
  IconData _getCategoryIcon() {
    final nombre = categoria.nombre.toLowerCase();

    if (nombre.contains('silla') || nombre.contains('sillon')) {
      return Icons.chair;
    } else if (nombre.contains('mesa')) {
      return Icons.table_restaurant;
    } else if (nombre.contains('cama') || nombre.contains('dormitorio')) {
      return Icons.bed;
    } else if (nombre.contains('escritorio') || nombre.contains('oficina')) {
      return Icons.desk;
    } else if (nombre.contains('estante') || nombre.contains('biblioteca')) {
      return Icons.bookmarks;
    } else if (nombre.contains('cocina')) {
      return Icons.kitchen;
    } else if (nombre.contains('exterior') || nombre.contains('jardin')) {
      return Icons.grass;
    } else {
      return Icons.category;
    }
  }
}