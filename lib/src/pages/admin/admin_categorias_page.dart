import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:myapp/src/model/categoria.dart';
import 'package:myapp/src/model/dao/categoriacrudimpl.dart';
import 'package:myapp/src/services/storage_service.dart';
import 'package:myapp/src/widgets/image_picker_widget.dart';

class AdminCategoriasPage extends StatefulWidget {
  const AdminCategoriasPage({Key? key}) : super(key: key);

  @override
  State<AdminCategoriasPage> createState() => _AdminCategoriasPageState();
}

class _AdminCategoriasPageState extends State<AdminCategoriasPage> {
  final CategoriaCrud _categoriaCrud = CategoriaCrud();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();

  List<Categoria> _categorias = [];
  List<Categoria> _categoriasFiltradas = [];
  bool _isLoading = true;

  static const Color _primaryColor = Color.fromARGB(255, 88, 23, 23);

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrar() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _categoriasFiltradas = List.from(_categorias);
      } else {
        _categoriasFiltradas = _categorias
            .where((c) =>
                c.nombre.toLowerCase().contains(query) ||
                c.descripcion.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoading = true);
    final categorias = await _categoriaCrud.leerCategorias();
    setState(() {
      _categorias = categorias;
      _categoriasFiltradas = List.from(categorias);
      _isLoading = false;
    });
  }

  void _mostrarFormulario({Categoria? categoria}) {
    final isEditing = categoria != null;
    final nombreController = TextEditingController(text: categoria?.nombre ?? '');
    final descripcionController = TextEditingController(text: categoria?.descripcion ?? '');
    String? imgUrl = categoria?.img;
    Uint8List? nuevaImagenBytes;
    String? nuevaImagenNombre;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 500,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(isEditing ? Icons.edit : Icons.add_circle, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(controller: nombreController, label: 'Nombre', hint: 'Ej: Dormitorios', icon: Icons.label),
                            SizedBox(height: 16),
                            _buildTextField(controller: descripcionController, label: 'Descripción', hint: 'Descripción de la categoría', icon: Icons.description, maxLines: 3),
                            SizedBox(height: 16),
                            ImagePickerWidget(
                              label: 'Imagen de categoría',
                              currentImageUrl: nuevaImagenBytes != null ? null : imgUrl,
                              onImageSelected: (bytes, fileName) {
                                setDialogState(() {
                                  nuevaImagenBytes = bytes;
                                  nuevaImagenNombre = fileName;
                                });
                              },
                            ),
                            if (nuevaImagenBytes != null)
                              Container(
                                width: double.infinity,
                                height: 150,
                                margin: EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(nuevaImagenBytes!, fit: BoxFit.cover),
                                      Positioned(
                                        top: 4, right: 4,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                                          child: Text('Nueva imagen', style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Footer
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (nombreController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('El nombre es requerido'), backgroundColor: Colors.red),
                                      );
                                      return;
                                    }
                                    setDialogState(() => isSubmitting = true);

                                    if (nuevaImagenBytes != null && nuevaImagenNombre != null) {
                                      final url = await _storageService.subirImagen(
                                        bucketName: 'categoria',
                                        bytes: nuevaImagenBytes!,
                                        fileName: nuevaImagenNombre!,
                                      );
                                      if (url != null) imgUrl = url;
                                    }

                                    final cat = Categoria(
                                      id: categoria?.id,
                                      nombre: nombreController.text.trim(),
                                      descripcion: descripcionController.text.trim(),
                                      img: imgUrl ?? '',
                                    );

                                    bool success;
                                    if (isEditing) {
                                      success = await _categoriaCrud.actualizarCategoria(cat);
                                    } else {
                                      final result = await _categoriaCrud.crearCategoria(cat);
                                      success = result != null;
                                    }

                                    setDialogState(() => isSubmitting = false);

                                    if (success) {
                                      Navigator.of(context).pop();
                                      _cargarCategorias();
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing ? 'Categoría actualizada' : 'Categoría creada'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red),
                                      );
                                    }
                                  },
                            icon: isSubmitting
                                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : Icon(isEditing ? Icons.save : Icons.add, size: 18),
                            label: Text(isEditing ? 'Guardar' : 'Crear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: icon != null ? Icon(icon, color: _primaryColor, size: 20) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primaryColor, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gestión de Categorías', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                          SizedBox(height: 4),
                          Text('${_categoriasFiltradas.length} de ${_categorias.length} categorías', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarFormulario(),
                      icon: Icon(Icons.add, size: 20),
                      label: Text('Nueva'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                // Buscador
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar categoría...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: _primaryColor, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Lista con acordeón
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)))
                : _categoriasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
                            SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty ? 'Sin resultados' : 'No hay categorías',
                              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _categoriasFiltradas.length,
                        itemBuilder: (context, index) {
                          final cat = _categoriasFiltradas[index];
                          return _buildCategoriaCard(cat);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(Categoria cat) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: cat.img.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  cat.img,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImg(),
                ),
              )
            : _placeholderImg(),
        title: Text(
          cat.nombre,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey[900]),
        ),
        subtitle: Text(
          'ID: ${cat.id}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: Colors.grey[200]),
          SizedBox(height: 12),
          // Descripción
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description, size: 16, color: Colors.grey[400]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  cat.descripcion.isNotEmpty ? cat.descripcion : 'Sin descripción',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Botón editar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _mostrarFormulario(categoria: cat),
              icon: Icon(Icons.edit, size: 16),
              label: Text('Editar categoría'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor),
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImg() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.image, color: Colors.grey[400], size: 22),
    );
  }
}
