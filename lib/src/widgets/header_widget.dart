import 'package:flutter/material.dart';

class HeaderWidget extends StatefulWidget {
  @override
  _HeaderWidgetState createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 23, 23),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.05),
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
                icon: Icon(Icons.menu, color: const Color.fromARGB(255, 255, 255, 255), size: 24),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              
              // Logo centrado
              Expanded(
                child: Center(
                  child: Text(
                    'VG MUEBLERIA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),
              
              // Espacio para mantener el logo centrado
              SizedBox(width: 48),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Campo de búsqueda debajo del logo 
          Center(
            child: Container(
              width: 1000, // Ajustar el ancho
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Navegación de categorías
          Container(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryItem('NOVEDADES', isSelected: true),
                _buildCategoryItem('LIVING'),
                _buildCategoryItem('EXTERIOR'),
                _buildCategoryItem('MESAS'),
                _buildCategoryItem('PARRILAS ELECTRICAS'),
                _buildCategoryItem('SOMIER'),
                _buildCategoryItem('TV'),
                _buildCategoryItem('MUEBLES MDF'),
                _buildCategoryItem('AIRES ACONDICIONADOS'),
                _buildCategoryItem('MESAS'),
                _buildCategoryItem('BUTACAS'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, {bool isSelected = false}) {
    return Container(
      margin: EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: const Color.fromARGB(255, 255, 255, 255),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 2,
            width: title.length * 8.0,
            color: isSelected ? const Color.fromARGB(255, 255, 255, 255) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}