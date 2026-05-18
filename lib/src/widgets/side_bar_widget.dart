import 'package:flutter/material.dart';
import 'package:myapp/src/model/categoria.dart';
import 'package:myapp/src/model/dao/categoriacrudimpl.dart';
import 'package:myapp/src/model/dao/usuariocrudimpl.dart';
import 'package:myapp/src/model/usuario.dart';
import 'package:myapp/src/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SideBarWidget extends StatefulWidget {
  @override
  _SideBarWidgetState createState() => _SideBarWidgetState();
}

class _SideBarWidgetState extends State<SideBarWidget> {
  final CategoriaCrud _categoriaCrud = CategoriaCrud();
  final UsuarioCrud _usuarioCrud = UsuarioCrud();
  late Future<List<Categoria>> _categoriasFuture;
  final String phoneNumber = "595985255566";
  final String message = "Hola, me interesa un producto";
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = _categoriaCrud.leerCategorias();
    _verificarRolUsuario();
  }

  Future<void> _verificarRolUsuario() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final usuario = await _usuarioCrud.obtenerUsuario(user.id);
        if (usuario != null && (usuario.fkCargo == 1 || usuario.fkCargo == 2)) {
          if (mounted) {
            setState(() => _esAdmin = true);
          }
        }
      }
    } catch (e) {
      print('Error al verificar rol: $e');
    }
  }

  Future<void> _openWhatsApp() async {
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header del sidebar
            Container(
              height: 120,
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 88, 23, 23),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'VG MUEBLERIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Lista de categorías principales
            Expanded(
              child: FutureBuilder<List<Categoria>>(
                future: _categoriasFuture,
                builder: (context, snapshot) {
                  // Mientras carga
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color.fromARGB(255, 88, 23, 23),
                        ),
                      ),
                    );
                  }

                  // Si hay error
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Error al cargar categorías',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  // Obtener las categorías
                  final categorias = snapshot.data ?? [];

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // NOVEDADES primero
                      _buildMainCategory(
                        'NOVEDADES',
                        Icons.fiber_new,
                        onTap: () {
                          Navigator.of(context).pop();
                          // Navegar a novedades
                          Navigator.pushNamed(context, '/');
                        },
                      ),

                      // Categorías de la base de datos
                      ...categorias.map(
                        (categoria) => _buildCategoryFromDB(categoria),
                      ),

                      Divider(height: 32, thickness: 1),

                      // Botón de Administración (solo para cargo 1 o 2)
                      /*
                      if (_esAdmin)
                        _buildMainCategory(
                          'ADMINISTRACIÓN',
                          Icons.admin_panel_settings,
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(context, AppRoutes.admin);
                          },
                        ),

                      if (_esAdmin)
                        Divider(height: 32, thickness: 1),
                      */

                      // Opciones adicionales
                      _buildMenuItem('Tienda', Icons.store_outlined, () {
                        Navigator.of(context).pop();
                        // Google Maps
                        launch('https://maps.app.goo.gl/6Y4nuN3BWAagVrqYA');
                      }),
                      _buildMenuItem(
                        'Contacto',
                        Icons.contact_support_outlined,
                        () {
                          Navigator.of(context).pop();
                          _openWhatsApp();
                        },
                      ),

                      Divider(height: 32, thickness: 1),

                      // Información adicional
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicio al cliente',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '+595 985 255 566',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color.fromARGB(255, 88, 23, 23),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                IconButton(
                                  icon: FaIcon(
                                    FontAwesomeIcons.facebook,
                                    color: const Color.fromARGB(255, 88, 23, 23),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    launch(
                                      'https://www.facebook.com/p/Muebles-VG-61579206785241/',
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                SizedBox(width: 12),
                                IconButton(
                                  icon: FaIcon(
                                    FontAwesomeIcons.instagram,
                                    color: const Color.fromARGB(255, 88, 23, 23),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    launch(
                                      'https://www.instagram.com/vgmuebleriapy?igsh=MXNkeDRtaHc1N2JzdA==',
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Botón de cerrar sesión
                      /*
                      if (Supabase.instance.client.auth.currentUser != null) ...[
                        Divider(height: 32, thickness: 1),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.of(context).pop(); // Cerrar drawer
                                await Supabase.instance.client.auth.signOut();
                                if (mounted) {
                                  Navigator.of(this.context).pushNamedAndRemoveUntil(
                                    AppRoutes.login,
                                    (route) => false,
                                  );
                                }
                              },
                              icon: Icon(Icons.logout, size: 18),
                              label: Text('Cerrar sesión'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                side: BorderSide(color: Colors.red[300]!),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      */
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategory(
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color.fromARGB(255, 88, 23, 23),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color.fromARGB(255, 88, 23, 23),
          letterSpacing: 0.5,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildCategoryFromDB(Categoria categoria) {
    return ListTile(
      title: Text(
        categoria.nombre.toUpperCase(),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color.fromARGB(255, 88, 23, 23),
          letterSpacing: 0.5,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop(); // Cerrar el drawer
        Navigator.pushNamed(
          context,
          AppRoutes.getCategoryRoute(categoria),
          arguments: categoria,
        );
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700], size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Colors.grey[700],
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}