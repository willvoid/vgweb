import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:myapp/src/model/producto.dart';
import 'package:myapp/src/model/categoria.dart';
import 'package:myapp/src/model/imagen.dart';
import 'package:myapp/src/model/dao/productocrudimpl.dart';
import 'package:myapp/src/model/dao/categoriacrudimpl.dart';
import 'package:myapp/src/model/dao/imagencrudimpl.dart';
import 'package:myapp/src/services/storage_service.dart';
import 'package:myapp/src/widgets/image_picker_widget.dart';

class AdminProductosPage extends StatefulWidget {
  const AdminProductosPage({Key? key}) : super(key: key);
  @override
  State<AdminProductosPage> createState() => _AdminProductosPageState();
}

class _AdminProductosPageState extends State<AdminProductosPage> {
  final Productocrudimpl _productoCrud = Productocrudimpl();
  final CategoriaCrud _categoriaCrud = CategoriaCrud();
  final ImagenCrud _imagenCrud = ImagenCrud();
  final StorageService _storageService = StorageService();

  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  bool _isLoading = true;
  static const Color _primaryColor = Color.fromARGB(255, 88, 23, 23);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final productos = await _productoCrud.leerProductos();
    final categorias = await _categoriaCrud.leerCategorias();
    setState(() {
      _productos = productos;
      _categorias = categorias;
      _isLoading = false;
    });
  }

  String _getNombreCategoria(int catId) {
    final cat = _categorias.where((c) => c.id == catId).toList();
    return cat.isNotEmpty ? cat.first.nombre : 'Sin categoría';
  }

  void _mostrarFormulario({Producto? producto}) {
    final isEditing = producto != null;
    final nombreCtrl = TextEditingController(text: producto?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: producto?.descripcion ?? '');
    final desc2Ctrl = TextEditingController(text: producto?.desc2 ?? '');
    final precioCtrl = TextEditingController(text: producto?.precio.toString() ?? '');
    final cuotasCtrl = TextEditingController(text: producto?.cuotas.toString() ?? '');
    final stockCtrl = TextEditingController(text: producto?.stock?.toString() ?? '0');
    int? selectedCategoriaId = producto?.categoria;
    int recomendado = producto?.recomendado ?? 1;
    String? imgUrl = producto?.img;
    Uint8List? nuevaImgBytes;
    String? nuevaImgNombre;
    bool isSubmitting = false;

    // Imágenes adicionales
    List<Imagen> imagenesExistentes = [];
    List<_NuevaImagen> nuevasImagenes = [];
    bool loadingImagenes = isEditing;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Cargar imágenes existentes al abrir
            if (isEditing && loadingImagenes) {
              _imagenCrud.leerImagenesPorProducto(producto!.id!).then((imgs) {
                setDialogState(() {
                  imagenesExistentes = imgs;
                  loadingImagenes = false;
                });
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 600,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
                            isEditing ? 'Editar Producto' : 'Nuevo Producto',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(ctx).pop(),
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
                            _field(nombreCtrl, 'Nombre', 'Ej: Mesa de comedor', Icons.label),
                            SizedBox(height: 14),
                            _field(descripcionCtrl, 'Descripción', 'Descripción corta', Icons.description, maxLines: 2),
                            SizedBox(height: 14),
                            _field(desc2Ctrl, 'Descripción detallada', 'Descripción larga', Icons.article, maxLines: 3),
                            SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(child: _field(precioCtrl, 'Precio', '0', Icons.attach_money, isNumber: true)),
                                SizedBox(width: 12),
                                Expanded(child: _field(cuotasCtrl, 'Cuotas', '0', Icons.credit_card, isNumber: true)),
                                SizedBox(width: 12),
                                Expanded(child: _field(stockCtrl, 'Stock', '0', Icons.inventory, isNumber: true)),
                              ],
                            ),
                            SizedBox(height: 14),
                            // Categoría dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categoría', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                                SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  value: selectedCategoriaId,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primaryColor, width: 2)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    isDense: true,
                                  ),
                                  hint: Text('Seleccionar categoría'),
                                  items: _categorias.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.nombre))).toList(),
                                  onChanged: (val) => setDialogState(() => selectedCategoriaId = val),
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            // Recomendado switch
                            SwitchListTile(
                              title: Text('Recomendado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: Text('Aparece en la sección de recomendados', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              value: recomendado == 1,
                              onChanged: (val) => setDialogState(() => recomendado = val ? 1 : 0),
                              activeColor: _primaryColor,
                              contentPadding: EdgeInsets.zero,
                            ),
                            Divider(height: 24),
                            // Imagen principal
                            Text('Imagen principal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                            SizedBox(height: 8),
                            ImagePickerWidget(
                              label: 'Imagen del producto',
                              currentImageUrl: nuevaImgBytes != null ? null : imgUrl,
                              onImageSelected: (bytes, name) {
                                setDialogState(() {
                                  nuevaImgBytes = bytes;
                                  nuevaImgNombre = name;
                                });
                              },
                            ),
                            if (nuevaImgBytes != null)
                              Container(
                                width: double.infinity, height: 120,
                                margin: EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(nuevaImgBytes!, fit: BoxFit.cover),
                                ),
                              ),
                            Divider(height: 24),
                            // Imágenes adicionales
                            Text('Imágenes adicionales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                            SizedBox(height: 8),
                            if (loadingImagenes)
                              Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            // Existentes
                            if (imagenesExistentes.isNotEmpty)
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: imagenesExistentes.map((img) => Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(img.urlImg, width: 80, height: 80, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[200], child: Icon(Icons.broken_image)),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2, right: 2,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await _imagenCrud.eliminarImagen(img.id!);
                                          setDialogState(() => imagenesExistentes.removeWhere((i) => i.id == img.id));
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                )).toList(),
                              ),
                            // Nuevas
                            if (nuevasImagenes.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: nuevasImagenes.asMap().entries.map((entry) => Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(entry.value.bytes, width: 80, height: 80, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 2, right: 2,
                                        child: GestureDetector(
                                          onTap: () => setDialogState(() => nuevasImagenes.removeAt(entry.key)),
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: Icon(Icons.close, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )).toList(),
                                ),
                              ),
                            SizedBox(height: 8),
                            ImagePickerWidget(
                              label: 'Agregar imagen adicional',
                              onImageSelected: (bytes, name) {
                                setDialogState(() => nuevasImagenes.add(_NuevaImagen(bytes: bytes, nombre: name)));
                              },
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
                            onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isSubmitting ? null : () async {
                              if (nombreCtrl.text.trim().isEmpty || selectedCategoriaId == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Nombre y categoría son requeridos'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              setDialogState(() => isSubmitting = true);

                              // Subir imagen principal si hay nueva
                              if (nuevaImgBytes != null && nuevaImgNombre != null) {
                                final url = await _storageService.subirImagen(
                                  bucketName: 'muebles',
                                  bytes: nuevaImgBytes!,
                                  fileName: nuevaImgNombre!,
                                );
                                if (url != null) imgUrl = url;
                              }

                              final prod = Producto(
                                id: producto?.id,
                                nombre: nombreCtrl.text.trim(),
                                descripcion: descripcionCtrl.text.trim(),
                                desc2: desc2Ctrl.text.trim(),
                                precio: int.tryParse(precioCtrl.text) ?? 0,
                                cuotas: int.tryParse(cuotasCtrl.text) ?? 0,
                                stock: int.tryParse(stockCtrl.text) ?? 0,
                                categoria: selectedCategoriaId!,
                                img: imgUrl ?? '',
                                recomendado: recomendado,
                              );

                              bool success;
                              int? productoId = producto?.id;
                              if (isEditing) {
                                success = await _productoCrud.actualizarProducto(prod);
                              } else {
                                final result = await _productoCrud.crearProducto(prod);
                                success = result != null;
                                productoId = result?.id;
                              }

                              // Subir imágenes adicionales
                              if (success && productoId != null && nuevasImagenes.isNotEmpty) {
                                for (final ni in nuevasImagenes) {
                                  final url = await _storageService.subirImagen(
                                    bucketName: 'muebles',
                                    bytes: ni.bytes,
                                    fileName: ni.nombre,
                                  );
                                  if (url != null) {
                                    await _imagenCrud.crearImagen(Imagen(
                                      urlImg: url,
                                      idProducto: productoId,
                                    ));
                                  }
                                }
                              }

                              setDialogState(() => isSubmitting = false);
                              if (success) {
                                Navigator.of(ctx).pop();
                                _cargarDatos();
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEditing ? 'Producto actualizado' : 'Producto creado'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
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

  Future<void> _confirmarEliminar(Producto producto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: [
          Icon(Icons.warning_amber, color: Colors.red, size: 28),
          SizedBox(width: 8),
          Text('Confirmar eliminación'),
        ]),
        content: Text('¿Eliminar "${producto.nombre}"?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _productoCrud.eliminarProducto(producto.id!);
      if (success) {
        _cargarDatos();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Producto eliminado'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: _primaryColor, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          Container(
            padding: EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestión de Productos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                    SizedBox(height: 4),
                    Text('${_productos.length} productos registrados', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _mostrarFormulario(),
                  icon: Icon(Icons.add, size: 20),
                  label: Text('Nuevo Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)))
                : _productos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            SizedBox(height: 16),
                            Text('No hay productos', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        scrollDirection: Axis.vertical,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: Offset(0, 2))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 72,
                                columnSpacing: 20,
                                horizontalMargin: 16,
                                columns: [
                                  DataColumn(label: Text('ID', style: _headerStyle)),
                                  DataColumn(label: Text('Imagen', style: _headerStyle)),
                                  DataColumn(label: Text('Nombre', style: _headerStyle)),
                                  DataColumn(label: Text('Categoría', style: _headerStyle)),
                                  DataColumn(label: Text('Precio', style: _headerStyle)),
                                  DataColumn(label: Text('Stock', style: _headerStyle)),
                                  DataColumn(label: Text('Rec.', style: _headerStyle)),
                                  DataColumn(label: Text('Acciones', style: _headerStyle)),
                                ],
                                rows: _productos.map((p) => DataRow(cells: [
                                  DataCell(Text('${p.id}', style: TextStyle(fontWeight: FontWeight.w500))),
                                  DataCell(
                                    p.img.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(p.img, width: 45, height: 45, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(width: 45, height: 45, color: Colors.grey[100], child: Icon(Icons.broken_image, size: 18)),
                                            ),
                                          )
                                        : Container(width: 45, height: 45, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                                            child: Icon(Icons.image, color: Colors.grey[400], size: 18)),
                                  ),
                                  DataCell(SizedBox(width: 150, child: Text(p.nombre, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)))),
                                  DataCell(Text(_getNombreCategoria(p.categoria), style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                                  DataCell(Text('${p.precio} Gs.', style: TextStyle(fontWeight: FontWeight.w600, color: _primaryColor))),
                                  DataCell(Text('${p.stock ?? 0}')),
                                  DataCell(Icon(p.esRecomendado() ? Icons.star : Icons.star_border, color: p.esRecomendado() ? Colors.amber : Colors.grey[400], size: 20)),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(icon: Icon(Icons.edit, color: _primaryColor, size: 20), tooltip: 'Editar', onPressed: () => _mostrarFormulario(producto: p)),
                                    IconButton(icon: Icon(Icons.delete, color: Colors.red[400], size: 20), tooltip: 'Eliminar', onPressed: () => _confirmarEliminar(p)),
                                  ])),
                                ])).toList(),
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

  TextStyle get _headerStyle => TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13);
}

class _NuevaImagen {
  final Uint8List bytes;
  final String nombre;
  _NuevaImagen({required this.bytes, required this.nombre});
}
