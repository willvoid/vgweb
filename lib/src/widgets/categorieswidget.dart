import 'package:flutter/material.dart';
import 'package:myapp/src/model/categoria.dart';
import 'package:myapp/src/model/dao/categoriacrudimpl.dart';
import 'package:myapp/src/routes/app_routes.dart';

class CategoriesScrollWidget extends StatefulWidget {
  @override
  _CategoriesScrollWidgetState createState() => _CategoriesScrollWidgetState();
}

class _CategoriesScrollWidgetState extends State<CategoriesScrollWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true;
  CategoriaCrud crud = CategoriaCrud();
  late Future<List<Categoria>> _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrows);
    // Cargar las categorías al inicializar
    _categoriasFuture = crud.leerCategorias();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrows() {
    setState(() {
      _showLeftArrow = _scrollController.offset > 0;
      _showRightArrow =
          _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
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
                  'EXPLORA POR CATEGORÍA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Encuentra el mobiliario perfecto para cada espacio',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Lista horizontal scrolleable con flechas
          Container(
            height: 220,
            child: FutureBuilder<List<Categoria>>(
              future: _categoriasFuture,
              builder: (context, snapshot) {
                // Mientras carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Si hay error
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar categorías',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                // Si no hay datos o está vacío
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay categorías disponibles'));
                }

                // Datos cargados exitosamente
                final categorias = snapshot.data!;

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 60),
                      itemCount: categorias.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(context, categorias[index]);
                      },
                    ),

                    // Flecha izquierda
                    if (_showLeftArrow)
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
                              onPressed: _scrollLeft,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                    // Flecha derecha
                    if (_showRightArrow)
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
                              onPressed: _scrollRight,
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

  Widget _buildCategoryCard(BuildContext context, Categoria category) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16, left: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              print('Navegando a ${category.nombre}');
              Navigator.pushNamed(
                context,
                AppRoutes.getCategoryRoute(category),
                arguments: category,
              );
            },
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagen de fondo
                Image.network(
                  category.img,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                ),

                // Gradiente oscuro
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),

                // Texto
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.nombre,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
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