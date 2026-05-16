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

  List<Categoria> _categorias = [];
  bool _isLoading = true;

  static const Color _primaryColor = Color.fromARGB(255, 88, 23, 23);

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoading = true);
    final categorias = await _categoriaCrud.leerCategorias();
    setState(() {
      _categorias = categorias;
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
                    // Header del dialog
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEditing ? Icons.edit : Icons.add_circle,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Body del dialog
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre
                            _buildTextField(
                              controller: nombreController,
                              label: 'Nombre',
                              hint: 'Ej: Dormitorios',
                              icon: Icons.label,
                            ),
                            SizedBox(height: 16),

                            // Descripción
                            _buildTextField(
                              controller: descripcionController,
                              label: 'Descripción',
                              hint: 'Descripción de la categoría',
                              icon: Icons.description,
                              maxLines: 3,
                            ),
                            SizedBox(height: 16),

                            // Imagen
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

                            // Preview de nueva imagen seleccionada
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
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Nueva imagen',
                                            style: TextStyle(color: Colors.white, fontSize: 11),
                                          ),
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

                    // Footer con botones
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey[200]!)),
                      ),
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

                                    // Subir imagen si hay una nueva
                                    if (nuevaImagenBytes != null && nuevaImagenNombre != null) {
                                      final url = await _storageService.subirImagen(
                                        bucketName: 'categoria',
                                        bytes: nuevaImagenBytes!,
                                        fileName: nuevaImagenNombre!,
                                      );
                                      if (url != null) {
                                        imgUrl = url;
                                      }
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
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(isEditing ? Icons.save : Icons.add, size: 18),
                            label: Text(isEditing ? 'Guardar' : 'Crear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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

  Future<void> _confirmarEliminar(Categoria categoria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[800], fontSize: 15),
            children: [
              TextSpan(text: '¿Estás seguro de eliminar la categoría '),
              TextSpan(
                text: '"${categoria.nombre}"',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '?\n\nEsta acción no se puede deshacer.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _categoriaCrud.eliminarCategoria(categoria.id!);
      if (success) {
        _cargarCategorias();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoría eliminada'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar. Puede tener productos asociados.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: icon != null ? Icon(icon, color: _primaryColor, size: 20) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
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
            padding: EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Categorías',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_categorias.length} categorías registradas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _mostrarFormulario(),
                  icon: Icon(Icons.add, size: 20),
                  label: Text('Nueva Categoría'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Tabla de categorías
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  )
                : _categorias.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
                            SizedBox(height: 16),
                            Text(
                              'No hay categorías',
                              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Creá tu primera categoría',
                              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 80,
                                columnSpacing: 24,
                                horizontalMargin: 20,
                                columns: [
                                  DataColumn(label: Text('ID', style: _headerStyle)),
                                  DataColumn(label: Text('Imagen', style: _headerStyle)),
                                  DataColumn(label: Text('Nombre', style: _headerStyle)),
                                  DataColumn(label: Text('Descripción', style: _headerStyle)),
                                  DataColumn(label: Text('Acciones', style: _headerStyle)),
                                ],
                                rows: _categorias
                                    .map(
                                      (cat) => DataRow(
                                        cells: [
                                          DataCell(Text('${cat.id}', style: TextStyle(fontWeight: FontWeight.w500))),
                                          DataCell(
                                            cat.img.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Image.network(
                                                      cat.img,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        width: 50,
                                                        height: 50,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[100],
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 20),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Icon(Icons.image, color: Colors.grey[400], size: 20),
                                                  ),
                                          ),
                                          DataCell(Text(cat.nombre, style: TextStyle(fontWeight: FontWeight.w600))),
                                          DataCell(
                                            SizedBox(
                                              width: 200,
                                              child: Text(
                                                cat.descripcion,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit, color: _primaryColor, size: 20),
                                                  tooltip: 'Editar',
                                                  onPressed: () => _mostrarFormulario(categoria: cat),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                                  tooltip: 'Eliminar',
                                                  onPressed: () => _confirmarEliminar(cat),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
        fontSize: 13,
      );
}
