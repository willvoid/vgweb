import 'package:flutter/material.dart';
import 'package:myapp/src/model/dao/productocrudimpl.dart';
import 'package:myapp/src/widgets/categorieswidget.dart';
import 'package:myapp/src/widgets/footer_widget.dart';
import 'package:myapp/src/widgets/image_location_widget.dart';
import 'package:myapp/src/widgets/product_row_widget.dart';
import 'package:myapp/src/widgets/productopopup.dart';
import 'package:myapp/src/widgets/base_page_widget.dart'; // Importar el nuevo widget

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Productocrudimpl crud = Productocrudimpl();

    return Stack(
      children: [
        BasePageWidget(
          selectedCategory: 'NOVEDADES', // Categoría seleccionada por defecto
          showCategoryNavigation: true,
          onCategoryTap: (category) {
            // TODO: Navegar a la página de categoría correspondiente
            print('Categoría seleccionada: $category');
          },
          children: [
            // Categorías
            CategoriesScrollWidget(),

            // Sección: Todos los productos (Grid)
            ProductsRowWidget(
              cargarProductos: () => crud.productosRecomendados(),
              titulo: 'RECOMENDADOS',
              subtitulo: 'Los productos recomendados de nuestra tienda',
            ),

            // Sección: Novedades (Carrusel horizontal)
            ProductsRowWidget(
              cargarProductos: () => crud.novedadesRecientes(limite: 10),
              titulo: 'NOVEDADES',
              subtitulo: 'Los productos más recientes de nuestra tienda',
            ),

            // Imagen de portada/ubicación
            ImageLocationWidget(imagePath: "/assets/icons/portadavg.jpg"),

            // Footer
            FooterWidget(),
          ],
        ),

        // Popup de producto aleatorio
        const ProductoAleatorioPopup(),
      ],
    );
  }
}