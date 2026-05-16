import 'package:flutter/material.dart';
import 'package:myapp/src/pages/admin/admin_categorias_page.dart';
import 'package:myapp/src/pages/admin/admin_productos_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  static const Color _primaryColor = Color.fromARGB(255, 88, 23, 23);

  final List<_AdminSection> _sections = [
    _AdminSection(
      title: 'Categorías',
      icon: Icons.category,
      page: const AdminCategoriasPage(),
    ),
    _AdminSection(
      title: 'Productos',
      icon: Icons.inventory_2,
      page: const AdminProductosPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              'Panel de Administración',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        elevation: 2,
      ),
      body: Row(
        children: [
          // Sidebar del admin
          _buildSidebar(isWide),

          // Línea divisoria
          VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),

          // Contenido principal
          Expanded(
            child: _sections[_selectedIndex].page,
          ),
        ],
      ),

      // Para pantallas pequeñas, usar bottom nav
      bottomNavigationBar: isWide
          ? null
          : null, // El sidebar siempre está visible como NavigationRail
    );
  }

  Widget _buildSidebar(bool isWide) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      extended: isWide,
      minWidth: 56,
      minExtendedWidth: 200,
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: _primaryColor),
      unselectedIconTheme: IconThemeData(color: Colors.grey[600]),
      selectedLabelTextStyle: TextStyle(
        color: _primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      indicatorColor: _primaryColor.withAlpha(30),
      leading: isWide
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _primaryColor.withAlpha(30),
                    child: Icon(
                      Icons.store,
                      color: _primaryColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'VG Admin',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  Divider(height: 24),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _primaryColor.withAlpha(30),
                child: Icon(Icons.store, color: _primaryColor, size: 18),
              ),
            ),
      destinations: _sections
          .map(
            (section) => NavigationRailDestination(
              icon: Icon(section.icon),
              selectedIcon: Icon(section.icon),
              label: Text(section.title),
            ),
          )
          .toList(),
    );
  }
}

class _AdminSection {
  final String title;
  final IconData icon;
  final Widget page;

  const _AdminSection({
    required this.title,
    required this.icon,
    required this.page,
  });
}
